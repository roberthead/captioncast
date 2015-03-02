require 'nokogiri'
require 'treat'

class DataFile < ActiveRecord::Base
  include Treat::Core::DSL

  @default_text_color = "#F7E694"
  @work

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#uploads and saves the file
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def self.save(upload)
    name =  upload['datafile'].original_filename
    directory = "public/data"
    #create the file path
    path = File.join(directory, name)
    File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
  end


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #add element to the element table
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def self.add_element(name, type, color, work_id)
      e = Element.find_or_create_by!(element_name: name, element_type: type, color: color, work: @work)
      e.save
  end


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #add the characters line to the Text table in the database
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def self.add_char_line(character, lineCount, charLine, visibility, work_id)
    txt = Text.create(sequence: lineCount, element: Element.find_by(element_name: character, element_type: 'CHARACTER'), work: @work, content_text: charLine, visibility: visibility)
    txt.save
  end


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #add the stage direction etc to the Text table in the database
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def self.add_direction(e_type, lineCount, direction, visibility, work_id)
    txt = Text.create(sequence: lineCount, element: Element.find_by(element_type: e_type), work: @work, content_text: direction, visibility: visibility)
    txt.save
  end



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #this is called in the controlers file when a file is uploaded
  # ** ONLY ACCEPTS .TXT OR .FDX FILES
  # .TXT file should be in the format
  # "CHARACTER NAME:" (all caps) "text goes here"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def self.parse_fd(upload, work)

    #create the file path abd open the file
    name =  upload['datafile'].original_filename
    directory = "public/data"
    path = File.join(directory, name)
    f = File.open(path)

    @work = Work.find_by_id(work)

    if(File.extname(path) == ".txt")
      self.parse_text_file(f, work)
      return

    elsif(File.extname(path) == ".fdx")
      doc =  Nokogiri::XML(f)
      f.close
      self.parse_fdx(doc, work)
      return
    end
  end



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #used to parse a .txt file script (typically other languages)
  #        This requires that text files be encoded with
  #
  #   Western (Windows 1252)  or    Western (ISO 8859-1) or   Western European (ISO) (Word)
  #                               in .txt format
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def self.parse_text_file(f, work)

    #reads the file line by line into array
    arr = IO.readlines(f)

    #adds all elements/character in the script to the database
    self.add_character_elements(arr, work)

    #add the lines in the script to the database depending on the character
    self.add_text_lines_to_db(arr, work)
  end



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #used for parsing script in .fdx format
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def self.parse_fdx(doc, work)

    #XPath for any Nondialogue Elements
    nondialouge = doc.xpath("/FinalDraft/Content/*[not(@Type='Dialogue')]")
    #add any nondialouge elemnts to the database
    self.add_fdx_nondialouge(nondialouge, work)


    #XPath for any characters.
    characters = doc.xpath("/FinalDraft/Content/Paragraph[@Type='Character']//Text")
    #add any nondialouge elemnts to the database
    self.add_fdx_character(characters, work)

    #add the lines to the database
    self.add_fdx_lines_to_db(doc, work)

  end



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#checks for character name in text file and adds it to the elements table if it does not already exist
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

def self.add_character_elements(arr, work)

    arr.each do |line|                                                                              #<- remove ".?" for future use (for error in spanish scripts)
      name = line.force_encoding("ISO-8859-1").encode("utf-8", replace: nil).match(/^[A-Z1-9\s\.]+(?=.?:)/)
      if (name != nil)
        #add the character "element" to the table if it does not exist
        character_name = name[0].upcase.lstrip.rstrip
        self.add_element(character_name, "CHARACTER", @default_text_color, work)
      end
    end
    #adds a blank line character for the editor to use for this work
    self.add_element("", "BLANKLINE", @default_text_color, work )
end



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #adds visible and non visible lines to database for FDX script
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def self.add_fdx_lines_to_db(doc, work)

    #xpath through the whole document for generaing entire script
    lines = doc.xpath("/FinalDraft/Content/Paragraph")
    lineCount = 0
    charName = ""

    #loops through the script and adds necessary lines into the database
    lines.each do |line|
      par_type = line.attributes["Type"].value.lstrip.rstrip
      #if its a character, get who and set character name
      if par_type.upcase == "CHARACTER"
        charName = line.children.children.text
        charName = charName.lstrip.rstrip #strip leading and trailing whitespace from name

      #gets the dialogue, character should alredy be set
      elsif par_type.upcase == "DIALOGUE"
        charLine = line.children.children.text
        #send the dialogue to be split into centenses and sent to database
        lineCount = self.split_into_sentences(charName.upcase, lineCount, charLine, work)
        #self.add_char_line(charName.upcase, lineCount, charLine, true, work)
        #lineCount += 1

      #gets parenthetical or action description (currently being ignored per request or Alayha)
      elsif par_type.upcase == "PARENTHETICAL" or par_type.upcase == "ACTION"
        #direction = line.children.children.text
        #self.add_direction(par_type.upcase, lineCount, direction, false, work)
        #lineCount += 1


      #catches all other non visible lines
      else
        direction = line.children.children.text
        self.add_direction(par_type.upcase, lineCount, direction, false, work)
        lineCount += 1
      end
    end
  end


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #adds character's lines the the database
  # - Takes an array which each index is a string/line from the script
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def self.add_text_lines_to_db(arr, work)

    cur_line = ""
    haveline = false
    lineCount = 1
    name = ""

    arr.each do |line|

      #look for a character name indicating the beginning of a dialogue                           <- remove ".?" for future use (for error in spanish scripts)
      a = line.force_encoding("ISO-8859-1").encode("utf-8", replace: nil).match(/^[A-Z1-9\s]+(?=.?:)/)

      #we have a completed monologue and need to submit it to the db
      if(a != nil and haveline == true)
        #here we send all the data to the database if its a dialogue
        lineCount = self.split_into_sentences(name, lineCount, cur_line, work)
        #self.add_char_line(name, lineCount, cur_line, true, work)
        haveline = false
        cur_line = ""
        name = ""
      end

      #we need to strip the name from the monologue
      if (a != nil)
        #get the character speaking
        name = a[0].upcase.lstrip.rstrip
        #returns just the line said by the character (removing excess whitespace)                     <- remove ".?" for future use (for error in spanish scripts)
        cur_line = line.force_encoding("ISO-8859-1").encode("utf-8", replace: nil).sub(/^[A-Z1-9\s]+.?:\s?/,"").squish
        haveline = true

      #we just append this line to our current characters script
      elsif (a == nil)                                                                                      #  <- remove ".?" for future use (for error in spanish scripts)
        cur_line += " " + line.force_encoding("ISO-8859-1").encode("utf-8", replace: nil).sub(/^[A-Z1-9\s]+.?:\s?/,"").squish
      end
    end
  end


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#takes any nondialouge element from .fdx after xpath() and adds it to the db
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def self.add_fdx_nondialouge(nondialouge, work)
      nondialouge.each do |nondialouge|
        type = nondialouge.attributes["Type"].value
        self.add_element("", type.to_str.upcase, @default_text_color, work)
    end
  end



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#takes any character element from .fdx after xpath() and adds it to the db
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def self.add_fdx_character(characters, work)
      characters.each do |character|
        name = character.text.to_str.upcase.lstrip.rstrip
        self.add_element(name, "CHARACTER", @default_text_color, work)
    end
  #adds a blank line character for editor to use for this work
  self.add_element("", "BLANKLINE", @default_text_color, work )
  end

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#takes any .txt line from the script, splits into centenses, and adds
# each centense into a line and adds that line to the database
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
def self.split_into_sentences(name, lineCount, cur_line, work)

  #split the current line into its centences
  sentences = self.split_by_sentence(line: cur_line)

  #add each sentence for this character into the database
  sentences.each do |sentence|
    self.add_char_line(name, lineCount, sentence, true, work)
    lineCount += 1
  end
  lineCount
end



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# takes a line from the script, splits into sentences and return an array
# containing the sentences found
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
def self.split_by_sentence(split_sentences: true, max_length: 60, line: nil)
  results = []

  line_section = Treat::Entities::Paragraph.build line
  line_section.apply :chunk, :segment

  line_section.sentences.each do |sentence|

    if split_sentences
      split_sentence = ''

      sentence.to_s.split(' ').each do |token|
        proposed_length = split_sentence.length + token.length
        if proposed_length > max_length
          results << split_sentence.rstrip
          split_sentence = ''
        end
        split_sentence << Treat::Entities::Token.from_string(token)
        split_sentence << " "
      end
      results << split_sentence.rstrip
    else
      results << sentence.to_s.rstrip
    end
  end
  results
end

end #end class

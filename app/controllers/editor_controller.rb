class EditorController < ApplicationController
	def index
		@work = Work.find_by_id(params['work'])
		@text = Text.all.where(work: params[:work]) #all the text lines
		#@size = Text.all.where(work: params[:work]).count

		@a = Array.new

		textLines = Text.where(work: params[:work])
		puts "textLines" + textLines.to_s
		
		textLines.each do |name|
		#gives each elements info
			hash_lines = {}#{:textLineSeq =>" ", :textLineId =>" ", :textText =>" ", :vis =>" ",:charName =>" ", :charId =>" "}
			puts "name: ***** " + name.to_s
			ch = Element.find_by(id: name.element_id)
			hash_lines[:textText] = name.content_text
			hash_lines[:textLineSeq] = name.sequence
			hash_lines[:textLineId] = name.id
			hash_lines[:charName] = ch.element_name
			hash_lines[:charId] = ch.id
			hash_lines[:vis] = name.visibility

			#push hash into array
			@a << hash_lines

		end
		# render json: @text
	end

	def select

		if request.post?
			# set position to the value stored in the operator record
			redirect_to :controller => 'editor', :action => 'index',
				:work => params['work']
		end
	end

	def edit 
		texts = Text.find_by(sequence: params['id'])
		puts texts.class.name
		if texts.class.name != 'Text'
			texts.each do |text|
				if text.work_id == params['work']
					@sample_text = text
				end
			end
		else
			@sample_text = texts
		end

		respond_to do |edit|
			edit.html
			edit.js
		end
	end

=begin
	def edit_stuff
		 @a = Array.new

		 hash_lines = {:textLineSeq =>" ", :textLineId =>" ", :textText =>" ", :vis =>" ",:charName =>" ", :charId =>" "}

		 textLines = Text.where(work: params[:work])

		 textLines.each do |name|
		 #gives each elements info
		 	ch = Element.find_by(id: name.element_id)
		 	hash_lines[:textText] = name.content_text
		 	hash_lines[:textLineSeq] = name.sequence
		 	hash_lines[:textLineId] = name.id
		 	hash_lines[:charName] = ch.element_name
		 	hash_lines[:charId] = ch.id
		 	hash_lines[:vis] = name.visibility

		 	#push hash into array
		 	@a.push(hash_lines)
		end
		
	end
=end

end

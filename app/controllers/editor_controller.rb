class EditorController < ApplicationController
	def index
		@text = Text.last.content_text
	end
end

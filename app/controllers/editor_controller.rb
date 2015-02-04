class EditorController < ApplicationController
	def index
		@work = Work.find_by_id(params['work'])
		@text = Text.all.where(work: params[:work])
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
end

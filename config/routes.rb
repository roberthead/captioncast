Rails.application.routes.draw do

  mount Bootsy::Engine => '/bootsy', as: 'bootsy'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  
  get  'display/select'
  post 'display/select'
  get  'display/index'
  get  'display/current'

  get  'upload/index'
  post 'upload/index'
  post 'upload/uploadFile'


  get  'cast/index'
  get  'cast/about'

  get  'operator/index'
  get  'operator/select'
  post 'operator/select'
  post 'operator/pushTextSeq'

  get  'editor/index'
  post 'editor/index'

  root 'cast#index'

end

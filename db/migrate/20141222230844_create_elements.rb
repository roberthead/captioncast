class CreateElements < ActiveRecord::Migration
  def change
    create_table :elements do |t|
	t.string :element_type
	t.string :color
      t.timestamps
    end
  end
end

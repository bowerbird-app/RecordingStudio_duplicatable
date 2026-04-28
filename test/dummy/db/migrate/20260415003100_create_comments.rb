class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments, id: :uuid do |t|
      t.string :author_name, null: false
      t.text :body, null: false
      t.references :commentable, polymorphic: true, null: false, type: :uuid

      t.timestamps
    end
  end
end

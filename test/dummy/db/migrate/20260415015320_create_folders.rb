class CreateFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :folders, id: :uuid do |t|
      t.references :workspace, uuid: true, null: false, foreign_key: true, type: :uuid
      t.references :parent_folder, uuid: true, null: true, foreign_key: { to_table: :folders }, type: :uuid
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end

    add_index :folders, [:workspace_id, :slug], unique: true
  end
end

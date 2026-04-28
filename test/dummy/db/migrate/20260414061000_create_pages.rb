class CreatePages < ActiveRecord::Migration[8.1]
  def change
    create_table :pages, id: :uuid do |t|
      t.references :workspace, null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.string :slug, null: false
      t.string :summary, null: false
      t.text :body, null: false
      t.text :code_sample
      t.boolean :published, null: false, default: true

      t.timestamps
    end

    add_index :pages, [ :workspace_id, :slug ], unique: true
  end
end

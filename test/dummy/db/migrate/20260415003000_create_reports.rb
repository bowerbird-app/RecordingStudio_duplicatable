class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports, id: :uuid do |t|
      t.references :workspace, null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.string :slug, null: false
      t.string :summary, null: false

      t.timestamps
    end

    add_index :reports, [ :workspace_id, :slug ], unique: true
  end
end

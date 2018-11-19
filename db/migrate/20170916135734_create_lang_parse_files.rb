class CreateLangParseFiles < ActiveRecord::Migration[5.0]
  def change
    create_table :lang_parse_files do |t|

      t.string :department
      t.string :act_number
      t.integer :parsed_size
      t.boolean :completed, default: false
      t.timestamps
    end
  end
end

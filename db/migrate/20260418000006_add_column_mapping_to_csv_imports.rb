class AddColumnMappingToCsvImports < ActiveRecord::Migration[8.1]
  def change
    add_column :csv_imports, :column_mapping, :text
  end
end

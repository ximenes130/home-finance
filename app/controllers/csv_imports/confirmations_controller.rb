class CsvImports::ConfirmationsController < ApplicationController
  before_action :set_csv_import

  def show
    @headers, @all_rows = @csv_import.parse_csv
    @mapping = @csv_import.column_mapping || {}
    @duplicates = @csv_import.find_duplicates
    @total_rows = @all_rows.size
    @duplicate_count = @duplicates.size
    @new_count = @total_rows - @duplicate_count
  end

  def create
    selected = (params[:selected_rows] || []).map(&:to_i)

    @csv_import.process_import(selected)
    redirect_to csv_import_path(@csv_import), notice: "Import completed successfully."
  rescue StandardError => e
    @csv_import.mark_failed
    redirect_to csv_import_path(@csv_import), alert: "Import failed: #{e.message}"
  end

  private
    def set_csv_import
      @csv_import = CsvImport.find(params[:csv_import_id])
    end
end

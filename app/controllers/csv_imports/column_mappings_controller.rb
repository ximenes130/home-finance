class CsvImports::ColumnMappingsController < ApplicationController
  before_action :set_csv_import

  def show
    @headers, @preview_rows = @csv_import.preview_rows
    @detected_mapping = @csv_import.column_mapping || @csv_import.detect_columns
  end

  def update
    @csv_import.update!(column_mapping: mapping_params)
    redirect_to csv_import_confirmation_path(@csv_import)
  rescue CSV::MalformedCSVError
    redirect_to csv_import_column_mapping_path(@csv_import), alert: "Could not parse the CSV file. Please check the format."
  end

  private
    def set_csv_import
      @csv_import = CsvImport.find(params[:csv_import_id])
    end

    def mapping_params
      permitted = params.require(:column_mapping).permit(*CsvImport::TRANSACTION_FIELDS)
      permitted.to_h.reject { |_, v| v.blank? }
    end
end

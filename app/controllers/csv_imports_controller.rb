class CsvImportsController < ApplicationController
  def index
    @csv_imports = CsvImport.recent.includes(:account)
  end

  def new
    @csv_import = CsvImport.new
    @accounts = Account.active.order(:name)
  end

  def create
    @csv_import = CsvImport.new(csv_import_params)

    if params[:csv_import][:file].blank?
      @csv_import.errors.add(:base, "Please select a CSV file")
      @accounts = Account.active.order(:name)
      render :new, status: :unprocessable_entity
      return
    end

    @csv_import.file.attach(params[:csv_import][:file])
    @csv_import.filename = params[:csv_import][:file].original_filename

    if @csv_import.save
      redirect_to csv_import_column_mapping_path(@csv_import)
    else
      @accounts = Account.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @csv_import = CsvImport.find(params[:id])
  end

  private
    def csv_import_params
      params.require(:csv_import).permit(:account_id)
    end
end

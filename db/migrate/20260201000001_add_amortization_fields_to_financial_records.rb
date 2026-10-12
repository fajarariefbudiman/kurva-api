class AddAmortizationFieldsToFinancialRecords < ActiveRecord::Migration[7.1]
  def change
    # Track optional capital-asset acquisition type, start date, and depreciation period.
    # Use straight-line monthly depreciation throughout the asset lifetime.
    add_column :financial_records, :jenis_akad, :string
    add_column :financial_records, :tanggal_mulai, :date
    add_column :financial_records, :durasi_bulan, :integer

    # Owner withdrawals (`prive`) reduce ending equity; inclusion is validated in the model.
  end
end

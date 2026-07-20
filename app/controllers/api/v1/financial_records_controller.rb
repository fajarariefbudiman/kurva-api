module Api
  module V1
    # Menangani Modal, Capex, Opex, Expense, dan Kas Masuk/Keluar —
    # semuanya lewat satu endpoint, dibedakan lewat query/body param `kind`.
    class FinancialRecordsController < BaseController
      VALID_KINDS = FinancialRecord::KINDS

      before_action :set_record, only: [:show, :update, :destroy]

      # GET /api/v1/financial_records?kind=capex&from=2026-01-01&to=2026-01-31
      def index
        records = current_user.financial_records.order(tanggal: :desc)
        records = records.of_kind(params[:kind]) if params[:kind].present?
        if params[:from].present? && params[:to].present?
          records = records.in_range(params[:from], params[:to])
        end
        render json: records
      end

      def show
        render json: @record
      end

      def create
        record = current_user.financial_records.new(record_params)
        record.save!
        render json: record, status: :created
      end

      def update
        @record.update!(record_params)
        render json: @record
      end

      def destroy
        @record.destroy!
        head :no_content
      end

      private

      def set_record
        @record = current_user.financial_records.find(params[:id])
      end

      def record_params
        p = params.require(:financial_record).permit(
          :kind, :nama, :kategori, :jumlah, :tanggal, :berulang, :catatan, :cash_session_id
        )
        unless VALID_KINDS.include?(p[:kind])
          raise ActionController::BadRequest, "kind harus salah satu dari: #{VALID_KINDS.join(', ')}"
        end
        p
      end
    end
  end
end

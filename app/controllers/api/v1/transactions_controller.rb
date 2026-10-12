module Api
  module V1
    class TransactionsController < BaseController
      # GET /api/v1/transactions?from=...&to=...
      def index
        txs = current_user.transactions.includes(:transaction_items).order(terjadi_pada: :desc)
        if params[:from].present? && params[:to].present?
          txs = txs.where(terjadi_pada: params[:from]..params[:to])
        end
        render json: txs.as_json(include: :transaction_items)
      end

      def show
        tx = current_user.transactions.includes(:transaction_items).find(params[:id])
        render json: tx.as_json(include: :transaction_items)
      end

      # POST /api/v1/transactions
      # Body: { transaction: { kasir, subtotal, diskon, total, payment_method_id, uang_diterima, kembalian, customer_id, cash_session_id, items: [{ product_id, nama, harga, harga_modal, qty }] } }
      # Default to cash when no payment method is configured.
      def create
        tx = current_user.transactions.new(transaction_params)
        tx.terjadi_pada ||= Time.current
        assign_payment_method!(tx)
        tx.save!
        render json: tx.as_json(include: :transaction_items), status: :created
      end

      private

      # Resolve the payment category and receipt label from `payment_method_id`, defaulting to cash.
      def assign_payment_method!(tx)
        pm_id = params.dig(:transaction, :payment_method_id)
        pm = pm_id.present? ? current_user.payment_methods.find_by(id: pm_id) : nil

        if pm
          tx.payment_method = pm
          tx.metode_pembayaran = pm.jenis
          tx.payment_method_label = pm.label
        else
          tx.metode_pembayaran = "tunai"
          tx.payment_method_label = "Tunai"
        end
      end

      def transaction_params
        params.require(:transaction).permit(
          :kasir, :subtotal, :diskon, :total, :metode_pembayaran,
          :uang_diterima, :kembalian, :customer_id, :cash_session_id, :terjadi_pada,
          transaction_items_attributes: [:product_id, :nama, :harga, :harga_modal, :qty]
        ).tap do |p|
          # Accept the shorter `items` key as an alias.
          if params[:transaction][:items].present? && p[:transaction_items_attributes].blank?
            p[:transaction_items_attributes] = params[:transaction][:items]
                                                  .map { |i| i.permit(:product_id, :nama, :harga, :harga_modal, :qty) }
          end
        end
      end
    end
  end
end

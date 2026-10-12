module Api
  module V1
    class PurchasesController < BaseController
      before_action :set_purchase, only: [:show, :update, :destroy, :lunasi]

      # GET /api/v1/purchases?from=...&to=...&status=hutang
      def index
        purchases = current_user.purchases.includes(:purchase_items, :supplier).order(terjadi_pada: :desc)
        purchases = purchases.where(terjadi_pada: params[:from]..params[:to]) if params[:from].present? && params[:to].present?
        purchases = purchases.where(status_pembayaran: params[:status]) if params[:status].present?
        render json: purchases.as_json(include: :purchase_items)
      end

      def show
        render json: @purchase.as_json(include: :purchase_items)
      end

      # POST /api/v1/purchases
      # Body: { purchase: { penerima, supplier_id, no_faktur, subtotal, diskon, total, status_pembayaran, metode_pembayaran, terjadi_pada, items: [{ product_id, nama, harga_beli, qty }] } }
      # Paid purchases reduce cash; credit purchases increase supplier debt; both update stock and unit cost.
      def create
        purchase = current_user.purchases.new(purchase_params)
        purchase.terjadi_pada ||= Time.current
        purchase.save!
        render json: purchase.as_json(include: :purchase_items), status: :created
      end

      # PATCH/PUT /api/v1/purchases/:id
      # Send the full `items` list when updating a purchase.
      # Reverse previous stock, cost, and payment effects before applying updated values.
      def update
        items_replaced = params[:purchase].present? &&
                          (params[:purchase][:purchase_items_attributes].present? ||
                           params[:purchase][:items].present?)

        ActiveRecord::Base.transaction do
          @purchase.reverse_side_effects!
          # Replace existing purchase items because client payloads do not include item IDs.
          @purchase.purchase_items.destroy_all if items_replaced
          @purchase.update!(purchase_params)
          @purchase.reload
          @purchase.apply_side_effects!
        end

        render json: @purchase.as_json(include: :purchase_items)
      end

      # DELETE /api/v1/purchases/:id
      # Deleting a purchase reverses its stock, cost, cash, and debt effects.
      def destroy
        @purchase.destroy!
        head :no_content
      end

      # PATCH /api/v1/purchases/:id/lunasi
      # Settling a credit purchase records cash outflow and reduces supplier debt.
      def lunasi
        if @purchase.lunasi_hutang!
          render json: @purchase.as_json(include: :purchase_items)
        else
          render json: { error: "Pembelian ini sudah lunas" }, status: :unprocessable_entity
        end
      end

      private

      def set_purchase
        @purchase = current_user.purchases.find(params[:id])
      end

      def purchase_params
        params.require(:purchase).permit(
          :penerima, :supplier_id, :no_faktur, :subtotal, :diskon, :total,
          :status_pembayaran, :metode_pembayaran, :terjadi_pada, :catatan,
          purchase_items_attributes: [:product_id, :nama, :harga_beli, :qty]
        ).tap do |p|
          # Accept the shorter `items` key as an alias.
          if params[:purchase][:items].present? && p[:purchase_items_attributes].blank?
            p[:purchase_items_attributes] = params[:purchase][:items]
                                               .map { |i| i.permit(:product_id, :nama, :harga_beli, :qty) }
          end
        end
      end
    end
  end
end

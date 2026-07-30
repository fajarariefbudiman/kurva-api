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
      # Body: { purchase: { penerima, supplier_id, no_faktur, subtotal, diskon, total,
      #                       status_pembayaran, metode_pembayaran, terjadi_pada,
      #                       items: [{ product_id, nama, harga_beli, qty }] } }
      #
      # status_pembayaran: "lunas" (default, dibayar sekarang) atau "hutang"
      # (belum dibayar, nambah hutang ke supplier). Stok & harga_modal produk
      # selalu diperbarui saat ini juga, terlepas dari status pembayaran —
      # karena barangnya memang sudah diterima secara fisik.
      def create
        purchase = current_user.purchases.new(purchase_params)
        purchase.terjadi_pada ||= Time.current
        purchase.save!
        render json: purchase.as_json(include: :purchase_items), status: :created
      end

      # PATCH/PUT /api/v1/purchases/:id
      # Body sama seperti create. Kirim ulang SELURUH daftar `items` (bukan
      # cuma yang berubah) — daftar barang lama akan diganti total dengan
      # yang baru.
      #
      # Efek lama (stok & harga modal produk, kas keluar/hutang supplier)
      # di-"undo" dulu memakai data yang MASIH LAMA, baru efek baru
      # diterapkan memakai data yang sudah diperbarui — supaya tidak
      # dobel maupun tercecer. Lihat Purchase#reverse_side_effects! &
      # #apply_side_effects!.
      def update
        items_replaced = params[:purchase].present? &&
                          (params[:purchase][:purchase_items_attributes].present? ||
                           params[:purchase][:items].present?)

        ActiveRecord::Base.transaction do
          @purchase.reverse_side_effects!
          # Item lama dihapus dulu (bukan di-update satu-satu) karena
          # payload dari client tidak menyertakan `id` tiap item — jadi
          # kalau tidak dihapus dulu, nested attributes akan menambah
          # item BARU di atas yang lama alih-alih menggantinya.
          @purchase.purchase_items.destroy_all if items_replaced
          @purchase.update!(purchase_params)
          @purchase.reload
          @purchase.apply_side_effects!
        end

        render json: @purchase.as_json(include: :purchase_items)
      end

      # DELETE /api/v1/purchases/:id
      # Menghapus pembelian sekaligus membatalkan efeknya: stok & harga
      # modal produk dikembalikan, kas/hutang terkait juga di-"undo" —
      # berjalan otomatis lewat `before_destroy :reverse_side_effects!`
      # di model Purchase.
      def destroy
        @purchase.destroy!
        head :no_content
      end

      # PATCH /api/v1/purchases/:id/lunasi
      # Melunasi pembelian yang tadinya berstatus "hutang": mencatat kas
      # keluar & mengurangi total_hutang supplier.
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
          # terima juga key `items` (lebih pendek) sebagai alias
          if params[:purchase][:items].present? && p[:purchase_items_attributes].blank?
            p[:purchase_items_attributes] = params[:purchase][:items]
                                               .map { |i| i.permit(:product_id, :nama, :harga_beli, :qty) }
          end
        end
      end
    end
  end
end

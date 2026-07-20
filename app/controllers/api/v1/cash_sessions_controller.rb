module Api
  module V1
    class CashSessionsController < BaseController
      # GET /api/v1/cash_sessions
      def index
        render json: current_user.cash_sessions.order(dibuka_pada: :desc)
      end

      # GET /api/v1/cash_sessions/active — sesi kas yang sedang buka (kalau ada)
      def active
        session = current_user.cash_sessions.open_session.first
        render json: session
      end

      # POST /api/v1/cash_sessions — buka kas baru
      def create
        if current_user.cash_sessions.open_session.exists?
          render json: { error: "Masih ada sesi kas yang belum ditutup" }, status: :unprocessable_entity
          return
        end

        session = current_user.cash_sessions.new(
          kasir: params[:kasir].presence || current_user.nama_toko,
          modal_awal: params[:modal_awal],
          dibuka_pada: Time.current
        )
        session.save!
        render json: session, status: :created
      end

      # PATCH /api/v1/cash_sessions/:id/close — tutup kas & hitung ringkasan
      def close
        session = current_user.cash_sessions.open_session.find(params[:id])
        txs = session.transactions

        total_tunai = txs.where(metode_pembayaran: "tunai").sum(:total)
        total_non_tunai = txs.where.not(metode_pembayaran: "tunai").sum(:total)
        total_hpp = txs.joins(:transaction_items)
                        .sum("transaction_items.harga_modal * transaction_items.qty")

        session.update!(
          ditutup_pada: Time.current,
          total_penjualan: total_tunai + total_non_tunai,
          total_tunai: total_tunai,
          total_non_tunai: total_non_tunai,
          total_hpp: total_hpp,
          kas_akhir_sistem: session.modal_awal + total_tunai,
          kas_akhir_fisik: params[:kas_akhir_fisik],
          selisih_kas: params[:kas_akhir_fisik].present? ? params[:kas_akhir_fisik].to_f - (session.modal_awal + total_tunai) : nil,
          jumlah_transaksi: txs.count,
          catatan: params[:catatan]
        )
        render json: session
      end
    end
  end
end

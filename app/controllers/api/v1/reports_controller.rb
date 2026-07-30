module Api
  module V1
    class ReportsController < BaseController
      # GET /api/v1/reports/summary?from=2026-07-01&to=2026-07-31
      #
      # Mengembalikan ringkasan lengkap: Modal, Capex, Opex, COGS, Expense,
      # total penjualan & laba kotor untuk rentang tanggal yang diminta.
      # Kalau from/to kosong, default-nya 30 hari terakhir.
      def summary
        from = (params[:from].presence && Date.parse(params[:from])) || 30.days.ago.to_date
        to = (params[:to].presence && Date.parse(params[:to])) || Date.current

        txs = current_user.transactions.where(terjadi_pada: from.beginning_of_day..to.end_of_day)
        total_penjualan = txs.sum(:total)
        total_cogs = txs.joins(:transaction_items)
                         .sum("transaction_items.harga_modal * transaction_items.qty")

        records = current_user.financial_records.in_range(from, to)
        total_modal = records.of_kind(%w[modal kas_masuk]).sum(:jumlah)
        total_capex = records.of_kind("capex").sum(:jumlah)
        total_opex = records.of_kind("opex").sum(:jumlah)
        total_expense = records.of_kind(%w[expense kas_keluar]).sum(:jumlah)

        # `pembelian_stok` & `bayar_hutang_supplier` SENGAJA tidak ikut
        # `total_expense` di atas -- itu perpindahan Kas ke Persediaan
        # (atau pelunasan Hutang), bukan beban. Bebannya sudah terwakili
        # lewat `total_cogs` di atas, yang diakui saat barang laku, bukan
        # saat dibeli. Di sini cuma ditampilkan sebagai info arus kas.
        total_pembelian_stok = records.of_kind(%w[pembelian_stok bayar_hutang_supplier]).sum(:jumlah)
        total_hutang_supplier = current_user.suppliers.sum(:total_hutang)

        render json: {
          periode: { dari: from, sampai: to },
          penjualan: {
            total_pendapatan: total_penjualan,
            jumlah_transaksi: txs.count,
            total_cogs: total_cogs,
            laba_kotor: total_penjualan - total_cogs
          },
          keuangan: {
            modal: total_modal,
            capex: total_capex,
            opex: total_opex,
            expense: total_expense
          },
          arus_kas: {
            pembelian_stok: total_pembelian_stok,
            hutang_supplier_saat_ini: total_hutang_supplier
          }
        }
      end
    end
  end
end

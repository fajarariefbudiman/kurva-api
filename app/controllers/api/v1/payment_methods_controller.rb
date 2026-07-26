module Api
  module V1
    class PaymentMethodsController < BaseController
      # GET /api/v1/payment_methods
      def index
        render json: current_user.payment_methods.order(created_at: :asc)
      end

      # POST /api/v1/payment_methods
      def create
        pm = current_user.payment_methods.new(payment_method_params)
        if pm.save
          render json: pm, status: :created
        else
          render json: { error: pm.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/payment_methods/:id
      def update
        pm = current_user.payment_methods.find(params[:id])
        if pm.update(payment_method_params)
          render json: pm
        else
          render json: { error: pm.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/payment_methods/:id
      def destroy
        pm = current_user.payment_methods.find(params[:id])
        pm.destroy
        head :no_content
      end

      private

      def payment_method_params
        params.require(:payment_method).permit(
          :nama, :jenis, :bank, :nomor_rekening, :atas_nama, :aktif
        )
      end
    end
  end
end

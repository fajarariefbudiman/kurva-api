module Api
  module V1
    class SuppliersController < BaseController
      before_action :set_supplier, only: [:show, :update, :destroy]

      def index
        render json: current_user.suppliers.order(:nama)
      end

      def show
        render json: @supplier
      end

      def create
        supplier = current_user.suppliers.new(supplier_params)
        supplier.save!
        render json: supplier, status: :created
      end

      def update
        @supplier.update!(supplier_params)
        render json: @supplier
      end

      def destroy
        @supplier.destroy!
        head :no_content
      end

      private

      def set_supplier
        @supplier = current_user.suppliers.find(params[:id])
      end

      def supplier_params
        params.require(:supplier).permit(:nama, :hp, :alamat)
      end
    end
  end
end

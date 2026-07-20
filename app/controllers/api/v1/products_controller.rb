module Api
  module V1
    class ProductsController < BaseController
      before_action :set_product, only: [:show, :update, :destroy]

      def index
        products = current_user.products.order(:nama)
        render json: products.as_json(only: %i[id nama kategori harga_jual harga_modal stok foto_url])
      end

      def show
        render json: @product
      end

      def create
        product = current_user.products.new(product_params)
        product.save!
        render json: product, status: :created
      end

      def update
        @product.update!(product_params)
        render json: @product
      end

      def destroy
        @product.destroy!
        head :no_content
      end

      private

      def set_product
        @product = current_user.products.find(params[:id])
      end

      def product_params
        params.require(:product).permit(:nama, :kategori, :harga_jual, :harga_modal, :stok, :foto_url)
      end
    end
  end
end

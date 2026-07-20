module Api
  module V1
    class CustomersController < BaseController
      before_action :set_customer, only: [:show, :update, :destroy]

      def index
        render json: current_user.customers.order(:nama)
      end

      def show
        render json: @customer
      end

      def create
        customer = current_user.customers.new(customer_params)
        customer.save!
        render json: customer, status: :created
      end

      def update
        @customer.update!(customer_params)
        render json: @customer
      end

      def destroy
        @customer.destroy!
        head :no_content
      end

      private

      def set_customer
        @customer = current_user.customers.find(params[:id])
      end

      def customer_params
        params.require(:customer).permit(:nama, :hp)
      end
    end
  end
end

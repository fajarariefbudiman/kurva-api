module Api
  module V1
    # Require authentication for all protected API resources.
    class BaseController < ApplicationController
      before_action :authenticate_user!
    end
  end
end

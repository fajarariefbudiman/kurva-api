module Api
  module V1
    # Semua resource di bawah /api/v1 (kecuali auth) wajib login.
    class BaseController < ApplicationController
      before_action :authenticate_user!
    end
  end
end

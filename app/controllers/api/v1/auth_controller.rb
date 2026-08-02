module Api
  module V1
    # Registrasi & login. Sengaja dipisah dari ApplicationController#authenticate_user!
    # karena dua aksi ini justru harus BOLEH diakses tanpa token.
    class AuthController < ApplicationController
      def register
        user = User.new(user_params)
        if user.save
          render json: { token: user.issue_token, user: user_json(user) }, status: :created
        else
          render json: { error: user.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email].to_s.downcase.strip)
        if user&.authenticate(params[:password].to_s)
          render json: { token: user.issue_token, user: user_json(user) }, status: :ok
        else
          render json: { error: "Email atau kata sandi salah" }, status: :unauthorized
        end
      end

      def me
        authenticate_user!
        return if performed?

        render json: { user: user_json(current_user) }
      end

      # PATCH /api/v1/auth/me — update profil toko (nama_toko, hp_toko, alamat).
      def update_me
        authenticate_user!
        return if performed?

        current_user.update!(profile_params)
        render json: { user: user_json(current_user) }
      end

      # PATCH /api/v1/auth/password — ganti kata sandi. Wajib sertakan kata sandi lama.
      def change_password
        authenticate_user!
        return if performed?

        unless current_user.authenticate(password_params[:current_password].to_s)
          render json: { error: "Kata sandi lama salah" }, status: :unauthorized
          return
        end

        current_user.password = password_params[:password]
        current_user.password_confirmation = password_params[:password_confirmation]

        if current_user.save
          render json: { user: user_json(current_user) }, status: :ok
        else
          render json: { error: current_user.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      private

      def password_params
        params.require(:user).permit(:current_password, :password, :password_confirmation)
      end

      def profile_params
        params.require(:user).permit(:nama_toko, :hp_toko, :alamat)
      end

      def user_params
        params.require(:user).permit(:nama_toko, :email, :password, :password_confirmation, :hp_toko, :alamat)
      end

      def user_json(user)
        { id: user.id, nama_toko: user.nama_toko, email: user.email, hp_toko: user.hp_toko, alamat: user.alamat }
      end
    end
  end
end
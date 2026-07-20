class ApplicationController < ActionController::API
  # Menangkap error umum supaya API selalu balas JSON yang rapi,
  # bukan menampilkan stack trace atau HTML error page ke client.
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActionController::BadRequest, with: :render_bad_request
  rescue_from ArgumentError, with: :render_bad_request

  attr_reader :current_user

  private

  # Dipanggil di controller mana pun yang butuh login (`before_action :authenticate_user!`).
  def authenticate_user!
    token = bearer_token
    payload = token && JsonWebToken.decode(token)

    if payload.nil?
      render_unauthorized("Token tidak valid atau sudah kedaluwarsa")
      return
    end

    @current_user = User.find_by(id: payload["user_id"])
    render_unauthorized("Akun tidak ditemukan") if @current_user.nil?
  end

  def bearer_token
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def render_not_found
    render json: { error: "Data tidak ditemukan" }, status: :not_found
  end

  def render_unprocessable(exception)
    render json: { error: exception.record.errors.full_messages.join(", ") },
           status: :unprocessable_entity
  end

  def render_bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end

# app/controllers/admin/sessions_controller.rb
module Admin
  class SessionsController < ApplicationController
    include Authentication

    allow_unauthenticated_access only: %i[new create]
    rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to admin_login_path, alert: "Try again later." }


    def new
      redirect_to admin_root_path if authenticated?
    end

    def create
      if user = User.authenticate_by(email_address: params[:email_address], password: params[:password])
        start_new_session_for(user)
        redirect_to admin_root_path
      else
        redirect_to admin_login_path, alert: "Try another email address or password."
      end
    end

    def destroy
      terminate_session
      redirect_to admin_login_path
    end
  end
end
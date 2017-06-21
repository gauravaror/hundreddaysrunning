class UserController < ApplicationController

  before_filter :require_login, except: [:login_home]

  def login_home
    if user_signed_in?
      redirect_to current_user
    end
  end

  def update_details
    @user = current_user
  end

  def save_details
    user = current_user
    user.update!(user_params)
    redirect_to root_url
  end

  def my_done_days
      @runs = current_user.runs
  end

  def submit_run
    PostWorker.perform_async(current_user.id, params['date'])
    redirect_to my_done_days_path
  end

  private

  def user_params
        params.require(:user).permit(:dob, :reporting_email)
  end

  def submit_params
    params.permit(:date, :user_id)
  end

  def require_login
  unless current_user
    redirect_to login_path
  end
end

end

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def strava
    # You need to implement the method below in your model (e.g. app/models/user.rb)
      @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Strava") if is_navigational_format?
    else
      session["devise.strava_data"] = request.env["omniauth.auth"]
    end
    redirect_to user_path
  end

  def failure
    redirect_to login_path
  end
end

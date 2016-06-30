class SettingsController < ApplicationController
  def edit
    @cfg = Settings.load_json
  end

  def update
    unless current_user.site_admin?
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end

    @cfg = Settings.defaults

    @cfg.each_key do |kk|
      @cfg[kk] = params[kk]
    end

    Settings.save_json(@cfg)

    redirect_to root_path, notice: "Settings Saved"
  end
end

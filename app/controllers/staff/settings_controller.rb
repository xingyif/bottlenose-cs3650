class Staff::SettingsController < Staff::BaseController
  before_filter :require_site_admin

  def edit
    @cfg = Settings.load_json
  end

  def update
    @cfg = Settings.defaults

    @cfg.each_key do |kk|
      @cfg[kk] = params[kk]
    end

    Settings.save_json(@cfg)

    redirect_to staff_root_path, notice: "Settings Saved"
  end
end

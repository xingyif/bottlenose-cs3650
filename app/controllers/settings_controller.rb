class SettingsController < ApplicationController
  def edit
    @cfg = Settings.load_json
  end

  def update
    @cfg = Settings.defaults

    @cfg.each_key do |kk|
      @cfg[kk] = params[kk]
    end

    Settings.save_json(@cfg)

    redirect_to root_path, notice: "Settings Saved"
  end
end

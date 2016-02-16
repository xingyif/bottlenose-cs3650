class MainController < ApplicationController
  skip_before_filter :ensure_current_user!, except: :dashboard

  def dashboard
  end

  def landing
  end

  def about
  end
end

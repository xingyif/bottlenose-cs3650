class MainController < ApplicationController
  skip_before_filter :require_logged_in_user, except: :dashboard

  def dashboard
  end

  def landing
  end

  def about
  end
end

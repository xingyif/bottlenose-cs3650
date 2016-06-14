class MainController < ApplicationController
  # skip_before_filter :require_current_user

  # GET /
  def home
    if current_user
      render "dashboard"
    else
      render "landing"
    end
  end

  # GET /about
  def about
  end
end

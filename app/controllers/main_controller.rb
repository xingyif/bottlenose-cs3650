class MainController < ApplicationController
  def index
    @user = User.new

    if current_user
      redirect_to courses_path
    end
  end

  def about
  end
end

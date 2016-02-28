module Staff
  class MainController < ApplicationController
    # GET /staff
    def dashboard
      render "dashboard"
    end
  end
end

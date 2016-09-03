class ErrorsController < ApplicationController
  def not_found
    respond_to do |format|
      format.html { render status: 404, layout: false }
    end
  rescue ActionController::UnknownFormat
    render status: 404, text: "nope"
  end
end

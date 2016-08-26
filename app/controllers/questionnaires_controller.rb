class QuestionnairesController < ApplicationController
  def show
    if @course.nil?
      redirect_to back_or_else(courses_questionnaires_path), alert: "No such course"
      return
    end
    @questionnaire = Questionnaire.find(params[:id])
  end

  def new
    @questionnaire = Questionnaire.new
  end

  def edit
    @questionnaire = Questionnaire.find(params[:id])
  end
  
  def update
  end

  def index
  end
end

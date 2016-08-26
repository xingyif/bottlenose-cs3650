class QuestionnairesController < ApplicationController
  def show
    @course = Course.find(params[:course_id])
    @questionnaire = Questionnaire.find(params[:id])
  end

  def new
    @course = Course.find(params[:course_id])
    @questionnaire = Questionnaire.new
  end

  def edit
    @course = Course.find(params[:course_id])
    @questionnaire = Questionnaire.find(params[:id])
  end
  
  def update
  end
end

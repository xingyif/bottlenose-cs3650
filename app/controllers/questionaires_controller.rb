class QuestionairesController < ApplicationController
  def show
    @course = Course.find(params[:course_id])
    @questionaire = Questionaire.find(params[:id])
  end

  def new
    @course = Course.find(params[:course_id])
    @questionaire = Questionaire.new
    3.times { @questionaire.questions.build }
  end

  def edit
    @course = Course.find(params[:course_id])
    @questionaire = Questionaire.find(params[:id])
  end
  
  def update
  end
end

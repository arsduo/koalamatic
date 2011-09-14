class RunsController < ApplicationController
  def index
    @runs = TestRun.page(params[:page])
  end

  def detail
    unless @run = TestRun.find_by_id(params[:id])
      flash[:status] = :missing_run
      redirect_to :action => :index and return
    end
  end

end

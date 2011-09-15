class RunsController < ApplicationController
  def index
    @page = params[:page] || 0
    @runs = TestRun.page(@page)
  end

  def detail
    unless params[:id] && @run = TestRun.find_by_id(params[:id])
      flash[:status] = :missing_run
      redirect_to :action => :index and return
    end
  end
end

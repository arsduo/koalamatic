class RunsController < ApplicationController
  def index
    @runs = Facebook::TestRun.order("id desc").page(0).per(5)
  end

  def page
    @page = params[:page] || 0
    @runs = Facebook::TestRun.order("id desc").page(@page)
  end

  def detail
    unless params[:id] && @run = Facebook::TestRun.find_by_id(params[:id])
      flash[:status] = :missing_run
      redirect_to :action => :index and return
    end
  end
end

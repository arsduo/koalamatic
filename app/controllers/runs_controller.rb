class RunsController < ApplicationController
  def index
    @runs = TestRun.page(params[:page])
  end

  def detail
  end

end

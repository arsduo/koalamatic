require 'spec_helper'

describe RunsController do

  describe "GET 'index'" do
    it "is successful" do
      get 'index'
      response.should be_success
    end
    
    it "gets the first page of runs if no params[:page] specified" do
      TestRun.expects(:page).with(nil).returns([])
      get 'index'
    end
    
    it "gets the first page of runs if no params[:page] specified" do
      page = "4"
      TestRun.expects(:page).with(page).returns([])
      get 'index', :page => page
    end
    
    it "provides the test runs to the view as @runs" do
      result = [1, 2, :a]
      TestRun.stubs(:page).returns(result)
      get 'index'
      assigns[:runs].should == result
    end
  end

end

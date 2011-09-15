require 'spec_helper'

describe RunsController do

  describe "GET 'index'" do
    it "is successful" do
      get 'index'
      response.should be_success
    end
    
    it "gets the first page of runs if no params[:page] specified" do
      TestRun.expects(:page).with(0).returns([])
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
  
  describe "GET 'detail'" do
    context "with a valid run" do
      before :each do
        @run = TestRun.make()
        @run.save        
      end
      
      it "makes the run available as @run" do
        get 'detail', :id => @run.id
        assigns[:run].should == @run
      end
    end
    
    context "without a valid run" do
      it "redirects to index if the run isn't provided" do
        get 'detail'
        response.should redirect_to(:action => :index)
      end
      
      it "redirects to index if the run doesn't exist" do
        get 'detail', :id => "abc"
        response.should redirect_to(:action => :index)
      end
      
      it "sets flash[:status] to :missing_run" do
        get 'detail', :id => "abc"
        flash[:status].should == :missing_run
      end
    end
  end

end

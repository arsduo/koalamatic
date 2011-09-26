require 'spec_helper'

describe RunsController do

  describe "GET 'index'" do
    before :each do
      @pageable_result = stub("pageable")
      @pageable_result.stubs(:per).returns(@pageable_result)
      TestRun.stubs(:page).returns(@pageable_result)
    end
    
    it "is successful" do
      get 'index'
      response.should be_success
    end
    
    it "gets the first page of runs" do
      TestRun.expects(:page).with(0).returns(@pageable_result)
      get 'index'
    end
    
    it "only gets a limited number of runs for the index page" do
      @pageable_result.expects(:per).with(5)
      get 'index'
    end
    
    it "provides the test runs to the view as @runs" do
      get 'index'
      assigns[:runs].should == @pageable_result
    end
  end
  
  describe "GET 'page'" do
    before :each do
      @pageable_result = stub("pageable")
      @pageable_result.stubs(:per).returns(@pageable_result)
      TestRun.stubs(:page).returns(@pageable_result)
    end
    
    it "is successful" do
      get 'page'
      response.should be_success
    end
    
    it "gets the first page of runs if no params[:page] specified" do
      TestRun.expects(:page).with(0).returns(@pageable_result)
      get 'page'
    end
        
    it "gets the appropriate page of runs if params[:page] specified" do
      page = "4"
      TestRun.expects(:page).with(page).returns(@pageable_result)
      get 'page', :page => page
    end
    
    it "provides the test runs to the view as @runs" do
      get 'page'
      assigns[:runs].should == @pageable_result
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

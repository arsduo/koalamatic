require 'spec_helper'

describe "RunsController routing" do
  describe "index" do
    it "roots the application to runs/index" do
      {:get => "/"}.should route_to(:controller => "runs", :action => "index")
    end
    
    it "routes GET index" do
      {:get => "/runs"}.should route_to(:controller => "runs", :action => "index")
    end

    it "routes GET index" do
      {:get => "/runs/index"}.should be_routable
    end
    
    it "routes GET page/:page" do
      {:get => "/runs/page/3"}.should route_to(:controller => "runs", :action => "index", :page => "3")
    end

    it "routes GET detail/id" do
      {:get => "/runs/detail/3"}.should route_to(:controller => "runs", :action => "detail", :id => "3")
    end    
  end
end
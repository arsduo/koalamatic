require 'spec_helper'

describe "API Controller routing" do
  describe "start_run" do
    it "routes GET start_run" do
      {:get => "/api/start_run"}.should be_routable
    end
  end
end
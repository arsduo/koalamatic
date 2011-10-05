require 'base/test_runner'
require 'facebook/api_recorder'

module Facebook
  class TestRunner < Koalamatic::Base::TestRunner
    # this class is not thread-safe
    # because RSpec configurations aren't thread-safe
    attr_reader :logger, :run

    SPEC_PATTERN = "**/*_spec.rb"

    def setup_test_environment
      # run the tests live
      ENV["LIVE"] = "true"      

      # setup the Faraday adapter
      Koala.http_service.faraday_middleware = Proc.new do |builder|
        builder.use Koala::MultipartRequest
        builder.request :url_encoded
        builder.use Koalamatic::Base::ApiRecorder
        builder.adapter Faraday.default_adapter
      end
      
      super
    end

    def get_tests
      add_load_path!
      load_koala_spec_helper!
      identify_tests(@path)
    end

    private

    # test case management
    def add_load_path!
      g = Bundler.load.specs.find {|s| s.name == "koala"}  
      @path = File.join(g.full_gem_path, "spec")
      $:.push(@path) unless $:.find {|p| p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}
      @path
    end

    def load_koala_spec_helper!
      # ensure the Koala spec helper is loaded, since require 'spec_helper' hits the Koalamatic helper
      require_file(File.join(@path, "spec_helper.rb"))
    end
  end
end
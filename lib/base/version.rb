module Koalamatic
  module Base
    class Version < ActiveRecord::Base
      has_many :test_runs
    end
  end
end

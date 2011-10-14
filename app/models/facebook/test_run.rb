require 'base/test_run'

class Facebook::TestRun < Koalamatic::Base::TestRun
  def initialize(*args)
    super
  end

  # PUBLISHING
  # this should perhaps be split out into a has_publishing module
  SUCCESS_TEXT = "All's well with Facebook!"
end

require 'test_helper'

class TestIntegration < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil S3deploy::VERSION
  end
end

require 'test_helper'

class TestConfig < Minitest::Test
  include S3deploy::TestHelper

  def test_config_init
    temp_dir = dir

    config = S3deploy::Config.new
    config.instance_eval do
      bucket ENV['TEST_BUCKET']
      app_path 's3deploytemp'
      dist_dir temp_dir

      environment(:production) do
        bucket ENV['PRODUCTION_BUCKET']
      end

      access_key_id ENV['AWS_ACCESS_KEY_ID']
      secret_access_key ENV['AWS_SECRET_ACCESS_KEY']
    end
    config.apply_environment_settings!

    assert_equal 's3deploytemp', config.app_path
    assert_equal dir, config.dist_dir
    assert_equal ENV['TEST_BUCKET'], config.bucket
    assert_equal ENV['AWS_ACCESS_KEY_ID'], config.access_key_id
    assert_equal ENV['AWS_SECRET_ACCESS_KEY'], config.secret_access_key
  end

  def test_config_environment
    temp_dir = dir

    ENV['ENV'] = 'production'

    config = S3deploy::Config.new
    config.instance_eval do
      bucket ENV['TEST_BUCKET']
      app_path 's3deploytemp'
      dist_dir temp_dir

      environment(:production) do
        bucket ENV['PRODUCTION_BUCKET']
      end

      access_key_id ENV['AWS_ACCESS_KEY_ID']
      secret_access_key ENV['AWS_SECRET_ACCESS_KEY']
    end
    config.apply_environment_settings!

    assert_equal 's3deploytemp', config.app_path
    assert_equal temp_dir, config.dist_dir
    assert_equal ENV['PRODUCTION_BUCKET'], config.bucket
    assert_equal ENV['AWS_ACCESS_KEY_ID'], config.access_key_id
    assert_equal ENV['AWS_SECRET_ACCESS_KEY'], config.secret_access_key
  end
end

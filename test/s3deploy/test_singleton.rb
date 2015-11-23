require 'test_helper'
require 'fileutils'

class TestSingleton < Minitest::Test
  include S3deploy::TestHelper

  def test_configure
    create_files!
    FileUtils.cd(File.dirname(dir)) do
      temp_dir = File.basename(dir)

      S3deploy.configure do
        bucket ENV['TEST_BUCKET']
        app_path 's3deploytemp'
        dist_dir temp_dir

        environment(:production) do
          bucket ENV['PRODUCTION_BUCKET']
        end

        access_key_id ENV['AWS_ACCESS_KEY_ID']
        secret_access_key ENV['AWS_SECRET_ACCESS_KEY']
      end

      assert_equal 's3deploytemp',
                   S3deploy.config.app_path
      assert_equal temp_dir,
                   S3deploy.config.dist_dir
      assert_equal ENV['TEST_BUCKET'],
                   S3deploy.config.bucket
      assert_equal ENV['AWS_ACCESS_KEY_ID'],
                   S3deploy.config.access_key_id
      assert_equal ENV['AWS_SECRET_ACCESS_KEY'],
                   S3deploy.config.secret_access_key
    end
  end
end

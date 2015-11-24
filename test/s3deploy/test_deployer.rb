require 'test_helper'

class TestDeployer < Minitest::Test
  include S3deploy::TestHelper

  def test_deployer_init
    S3deploy::Deployer.new(
      dist_dir: dir,
      bucket: ENV['TEST_BUCKET'],
      app_path: 's3deploytemp'
    )
  end

  def test_everything
    create_files!

    url_tmpl = "http://s3.amazonaws.com/#{ENV['TEST_BUCKET']}/s3deploytemp/%s"
    d = S3deploy::Deployer.new(
      dist_dir: dir,
      bucket: ENV['TEST_BUCKET'],
      app_path: 's3deploytemp',
      logger: logger
    )

    d.deploy!
    sleep 5

    url = URI.parse(url_tmpl % 'index.html')
    req = Net::HTTP.new(url.host, url.port)
    res = req.request_head(url.path)
    assert_equal 200, res.code.to_i, "#{res.code} #{url}"

    url = URI.parse(url_tmpl % 'app.css')
    res = req.request_head(url.path)
    assert_equal 200, res.code.to_i, "#{res.code} #{url}"

    update_files!

    d.deploy_file!('circle.svg')
    sleep 5

    url = URI.parse(url_tmpl % 'circle.svg')
    res = req.request_head(url.path)
    assert_equal 200, res.code.to_i, "#{res.code} #{url}"

    url_tmpl = "http://s3.amazonaws.com/#{ENV['TEST_BUCKET']}/foo-bar/%s"

    d.delete!
    sleep 5

    url = URI.parse(url_tmpl % 'index.html')
    res = req.request_head(url.path)
    assert_equal 403, res.code.to_i, "#{res.code} #{url}"
  end
end

require 'test_helper'

class TestDeployer < Minitest::Test
  def test_everything
    skip

    FileUtils.mkdir_p(wd.expand 'build')
    open(wd.expand('build/index.html'), 'w') do |fp|
      fp.write('<h1>Hello World!</h1>')
    end
    open(wd.expand('build/app.css'), 'w') do |fp|
      fp.write('h1 { font-size: 100px }')
    end
    assert File.exist?(wd.expand 'build/index.html'), 'File should exist'
    assert File.exist?(wd.expand 'build/app.css'), 'File should exist'

    d.deploy(wd.expand 'build')

    sleep 5

    url = URI.parse('http:' + d.url_for('/'))
    req = Net::HTTP.new(url.host, url.port)
    res = req.request_head(url.path)
    assert_equal 200, res.code.to_i, "#{res.code} #{url}"

    sleep 5

    url = URI.parse('http:' + d.url_for('app.css'))
    res = req.request_head(url.path)
    assert_equal 200, res.code.to_i, "#{res.code} #{url}"

    open(wd.expand('thumb.svg'), 'w') do |fp|
      fp.write('<svg><circle /></svg>')
    end
    assert File.exist?(wd.expand 'thumb.svg'), 'File should exist'

    d.deploy_file(p.working_dir, 'thumb.svg')

    sleep 5

    url = URI.parse('http:' + d.url_for('thumb.svg'))
    res = req.request_head(url.path)
    assert_equal 200, res.code.to_i, "#{res.code} #{url}"

    skip

    old_check_url = d.url_for('index.html')

    p.slug = 'foo-bar'
    d.move!

    sleep 5

    url = URI.parse('http:' + old_check_url)
    res = req.request_head(url.path)
    assert_equal 404, res.code.to_i, "#{res.code} #{url}"

    sleep 5

    url = URI.parse('http:' + d.url_for('index.html'))
    res = req.request_head(url.path)
    assert_equal 200, res.code.to_i, "#{res.code} #{url}"

    d.delete!

    sleep 5

    url = URI.parse('http:' + d.url_for('index.html'))
    res = req.request_head(url.path)
    assert_equal 404, res.code.to_i, "#{res.code} #{url}"
  end
end

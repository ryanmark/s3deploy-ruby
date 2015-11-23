require 's3deploy'
require 'fileutils'

module S3deploy
  # Helper test class
  module TestHelper
    def before_setup
      @dirs = {}
      @fixtures = {}
    end

    def after_setup
      skip unless ENV['TEST_BUCKET'] &&
                  ENV['PRODUCTION_BUCKET'] &&
                  ENV['AWS_ACCESS_KEY_ID'] &&
                  ENV['AWS_SECRET_ACCESS_KEY']

      ENV.delete 'ENV'
    end

    def after_teardown
      @dirs.values.each do |dir|
        FileUtils.rm_rf(dir) if File.exist?(dir)
      end
    end

    # Get a temp dir that will get cleaned-up after this test
    # @param name [Symbol] name name of the tmpdir to get
    # @return [Pathname] absolute path
    def dir(name = :test)
      @dirs[name.to_sym] ||= Pathname.new(
        File.expand_path("#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/"))
    end

    # Add files
    def create_files!(name = :test)
      html_file = File.expand_path('index.html', dir(name))
      css_file = File.expand_path('app.css', dir(name))
      svg_file = File.expand_path('circle.svg', dir(name))

      refute File.exist?(html_file), 'File should not exist'
      refute File.exist?(css_file), 'File should not exist'
      refute File.exist?(svg_file), 'File should not exist'

      FileUtils.mkdir_p(dir(name))

      open(html_file, 'w') do |fp|
        fp.puts('<link rel="stylesheet" type="text/css" href="app.css">')
        fp.puts('<h1>Hello World!</h1>')
      end

      open(css_file, 'w') do |fp|
        fp.puts('h1 { font-size: 100px; font-family:Comic Sans; }')
      end

      assert File.exist?(html_file), 'File should exist'
      assert File.exist?(css_file), 'File should exist'
      refute File.exist?(svg_file), 'File should not exist'
    end

    # update files
    def update_files!(name = :test)
      html_file = File.expand_path('index.html', dir(name))
      css_file = File.expand_path('app.css', dir(name))
      svg_file = File.expand_path('circle.svg', dir(name))

      assert File.exist?(html_file), 'File should exist'
      assert File.exist?(css_file), 'File should exist'
      refute File.exist?(svg_file), 'File should not exist'

      open(html_file, 'a') do |fp|
        fp.puts('<img src="circle.svg">')
      end

      open(svg_file, 'w') do |fp|
        fp.puts('<svg height="100" width="100"><circle cx="50" cy="50" r="40" fill="red" /></svg>')
      end

      assert File.exist?(html_file), 'File should exist'
      assert File.exist?(css_file), 'File should exist'
      assert File.exist?(svg_file), 'File should exist'
    end

    def logger
      @logger ||= Logger.new('/dev/null')
    end
  end
end

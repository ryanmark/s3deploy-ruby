require 'aws/s3'
require 'mime/types'
require 'digest/md5'
require 'zlib'
require 'stringio'
require 's3deploy/version'
require 's3deploy/color'
require 's3deploy/stream'
require 'logger'

module S3deploy
  # Class to manage a deployment
  class Deployer
    def initialize(opts)
      @dist_dir      = opts[:dist_dir]
      @bucket        = opts[:bucket]
      @app_path      = opts[:app_path] || ''
      @gzip          = opts[:gzip] || S3deploy::DEFAULT_GZIP
      @acl           = opts[:acl] || :public_read
      @cache_control = opts[:cache_control] || 'public,max-age=60'
      @exclude       = opts[:exclude] || nil

      if opts[:logger]
        @logger = opts[:logger]
      else
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
        @logger.formatter = proc { |_lvl, _dt, _name, msg| "#{msg}\n" }
      end

      @conn = AWS::S3.new(
        access_key_id: opts[:access_key_id] || ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: opts[:secret_access_key] || ENV['AWS_SECRET_ACCESS_KEY'])
    end

    def deploy!
      files_changed = files_skipped = 0
      source_files_list.each do |file|
        if deploy_file! file
          files_changed += 1
        else
          files_skipped += 1
        end
      end
      @logger.info('Deploy complete. ' +
                   colorize(:yellow, "#{files_changed} files updated") +
                   ", #{files_skipped} files unchanged")
    end

    def deploy_file!(file)
      file = File.expand_path(file, @dist_dir).to_s
      dir = app_path_with_bucket
      s3_file_dir = Pathname.new(
        File.dirname(file)).relative_path_from(
          Pathname.new(@dist_dir)).to_s
      absolute_s3_file_dir = s3_file_dir == '.' ? dir : File.join(dir, s3_file_dir)
      store_value(
        File.basename(file),
        File.read(file),
        absolute_s3_file_dir)
    end

    private

    def app_path_with_bucket
      File.join(@bucket, @app_path)
    end

    def get_value(key, path)
      @logger.info("Retrieving value #{key} from #{path} on S3")
      parts = path.split('/') + [key]
      bucket = @conn.buckets[parts.shift]
      bucket.objects[parts.join('/')].read
    end

    def store_value(key, value, path)
      parts = path.split('/') + [key]
      bucket = @conn.buckets[parts.shift]
      obj = bucket.objects[parts.join('/')]

      mime = MIME::Types.type_for(key).first
      if mime.nil?
        content_type = 'text/plain'
      else
        content_type = mime.content_type
      end

      md5 = Digest::MD5.hexdigest(value).to_s
      if obj.exists?
        checksum = obj.head.meta['md5_checksum']
        return false if md5 == checksum
      end

      options = {
        acl: @acl,
        cache_control: @cache_control,
        content_type: content_type,
        metadata: {
          md5_checksum: md5
        }
      }
      if should_compress?(key)
        options[:content_encoding] = 'gzip'
        value = compress(value)
      end

      msg = "Upload #{colorize(:yellow, key)} to #{colorize(:yellow, path)} on S3"
      msg += ", #{colorize(:green, 'gzipped')}" if should_compress?(key)
      @logger.info(msg)

      obj.write(value, options)
      true
    end

    def should_compress?(key)
      if [true, false, nil].include?(@gzip)
        @gzip ? true : false
      else
        @gzip.each do |re|
          return true if key =~ re
        end
        false
      end
    end

    def compress(source)
      output = Stream.new
      gz = Zlib::GzipWriter.new(
        output, Zlib::DEFAULT_COMPRESSION, Zlib::DEFAULT_STRATEGY)
      gz.write(source)
      gz.close
      output.string
    end

    def decompress(source)
      Zlib::GzipReader.new(StringIO.new(source)).read
    rescue Zlib::GzipFile::Error
      source
    end

    def source_files_list
      files = Dir.glob(File.join(@dist_dir, '**/*'))
      if @exclude.is_a? Array
        files.select do |f|
          File.file?(f) && @exclude.reduce(false) do |m, c|
            m || c.match(f)
          end
        end
      elsif @exclude.is_a? Regexp
        files.select do |f|
          File.file?(f) && !@exclude.match(f)
        end
      else
        files.select { |f| File.file?(f) }
      end
    end

    def colorize(color, text)
      Color.send(color, text)
    end
  end
end

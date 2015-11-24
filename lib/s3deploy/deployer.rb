require 'aws-sdk'
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
    include Color

    attr_reader :s3
    def initialize(opts)
      @dist_dir      = File.expand_path(opts[:dist_dir])
      @bucket        = opts[:bucket]
      @app_path      = strip_slashes(opts[:app_path]) || ''
      @gzip          = opts[:gzip] || S3deploy::DEFAULT_GZIP
      @acl           = opts[:acl] || 'public-read'
      @cache_control = opts[:cache_control] || 'public,max-age=60'
      @exclude       = opts[:exclude] || nil

      if opts[:logger]
        @logger = opts[:logger]
      else
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
        @logger.formatter = proc { |_lvl, _dt, _name, msg| "#{msg}\n" }
      end

      @s3 = Aws::S3::Client.new(
        access_key_id: opts[:access_key_id] || ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: opts[:secret_access_key] || ENV['AWS_SECRET_ACCESS_KEY'],
        region: opts[:region] || ENV['AWS_REGION'] || 'us-east-1')
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

      @logger.info('Deployed to S3. ' +
                   colorize(:yellow, "#{files_changed} files updated") +
                   ", #{files_skipped} files unchanged")
    end

    def deploy_file!(file)
      file = File.expand_path(file, @dist_dir).to_s

      unless File.exist?(file) && file.start_with?(@dist_dir)
        raise "File must be in #{@dist_dir}"
      end

      s3_file_dir = File.dirname(strip_slashes(file[@dist_dir.length..-1].to_s))

      if s3_file_dir.empty? || s3_file_dir == '.'
        absolute_s3_file_dir = app_path_with_bucket
      else
        absolute_s3_file_dir = "#{app_path_with_bucket}/#{s3_file_dir}"
      end

      store_value(
        File.basename(file),
        File.read(file),
        absolute_s3_file_dir)
    end

    def delete!
      marker = nil
      files_deleted = 0
      loop do
        args = {
          bucket: @bucket,
          prefix: @app_path
        }

        args[:marker] = marker unless marker.nil?

        list = @s3.list_objects(args)

        break if list.contents.nil? || list.contents.empty?

        files_deleted += list.contents.length

        list.contents.each do |i|
          msg = "Delete #{colorize(:red, "#{@bucket}/#{i.key}")}"
          @logger.info(msg)
        end

        @s3.delete_objects(
          bucket: @bucket,
          delete: {
            objects: list.contents.map { |i| { key: i.key } }
          }
        )

        break unless list.is_truncated

        marker = list.next_marker
      end

      @logger.info('Deleted from S3. ' +
                   colorize(:red, "#{files_deleted} files removed"))
      true
    rescue Aws::S3::Errors::NotFound
      false
    end

    private

    def app_path_with_bucket
      "#{@bucket}/#{@app_path}"
    end

    def strip_slashes(str)
      str.gsub(%r{(^/|/$)}, '')
    end

    def get_value(key, path)
      @logger.info("Retrieving value #{key} from #{path} on S3")
      parts = path.split('/') + [key]
      @s3.get_object(bucket: parts.shift, key: parts.join('/')).body.read
    end

    def head_value(key, path)
      parts = path.split('/') + [key]
      @s3.head_object(
        bucket: parts.shift,
        key: parts.join('/'))
    rescue Aws::S3::Errors::NotFound
      false
    end

    def store_value(key, value, path)
      md5 = Digest::MD5.hexdigest(value).to_s
      resp = head_value(key, path)
      if resp
        checksum = resp.metadata['md5_checksum']
        return false if md5 == checksum
      end

      mime = MIME::Types.type_for(key).first
      if mime.nil?
        content_type = 'text/plain'
      else
        content_type = mime.content_type
      end

      parts = path.split('/') + [key]
      options = {
        bucket: parts.shift,
        key: parts.join('/'),
        acl: @acl,
        cache_control: @cache_control,
        content_type: content_type,
        metadata: {
          md5_checksum: md5
        }
      }

      if should_compress?(key)
        options[:content_encoding] = 'gzip'
        options[:body] = compress(value)
      else
        options[:body] = value
      end

      msg = "Upload #{colorize(:yellow, "#{path}/#{key}")}"
      msg += ", #{colorize(:green, 'gzipped')}" if should_compress?(key)
      @logger.info(msg)

      @s3.put_object(options)
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
  end
end

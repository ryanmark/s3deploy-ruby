require 'aws/s3'
require 'mime/types'
require 'digest/md5'
require 'zlib'
require 'stringio'
require 's3deploy/version'
require 's3deploy/color'
require 's3deploy/config'

module S3deploy
  class << self
    attr_reader :config

    def configure(&block)
      @config = Config.new
      @config.instance_eval(&block)
      @config.apply_environment_settings!

      @conn = AWS::S3.new(
        access_key_id: config.access_key_id,
        secret_access_key: config.secret_access_key)
    end

    def deploy!
      config.before_deploy if config.before_deploy
      copy_files_to_s3
      config.after_deploy if config.after_deploy
    end

    private

    def copy_files_to_s3()
      dir = app_path_with_bucket
      uploaded = false
      files_changed = files_skipped = 0
      source_files_list.each do |file|
        s3_file_dir = Pathname.new(
          File.dirname(file)).relative_path_from(
            Pathname.new(config.dist_dir)).to_s
        absolute_s3_file_dir = s3_file_dir == '.' ? dir : File.join(dir, s3_file_dir)
        uploaded = store_value(
          File.basename(file),
          File.read(file),
          absolute_s3_file_dir)
        if uploaded
          files_changed += 1
        else
          files_skipped += 1
        end
      end
      puts 'Deploy complete. ' +
           colorize(:yellow, "#{files_changed} files updated") +
           ", #{files_skipped} files unchanged"
    end

    def app_path_with_bucket
      File.join(config.bucket, config.app_path)
    end

    def get_value(key, path)
      puts "Retrieving value #{key} from #{path} on S3"
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
      checksum = obj.head.meta['md5_checksum']
      return false if md5 == checksum

      options = {
        acl: :public_read,
        cache_control: 'public,max-age=60',
        content_type: content_type,
        metadata: {
          md5_checksum: md5
        }
      }
      if should_compress?(key)
        options[:content_encoding] = 'gzip'
        value = compress(value)
      end

      puts "Upload #{colorize(:yellow, key)} to #{colorize(:yellow, path)} on S3#{", #{colorize(:green, 'gzipped')}" if should_compress?(key)}"

      obj.write(value, options)
      true
    end

    def should_compress?(key)
      if [true, false, nil].include?(config.gzip)
        !!config.gzip
      else
        for re in config.gzip
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
      Dir.glob(File.join(config.dist_dir, '**/*')).select { |f| File.file?(f) }
    end

    def colorize(color, text)
      Color.send(color, text)
    end

    class Stream < StringIO
      def initialize(*)
        super
        set_encoding 'BINARY'
      end

      def close
        rewind
      end
    end

  end
end

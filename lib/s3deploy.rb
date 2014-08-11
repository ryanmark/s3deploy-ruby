require 'aws/s3'
require 'zlib'
require 'stringio'
require 's3deploy/version'
require 's3deploy/config'

module S3deploy
  class << self
    attr_reader :config

    def configure(&block)
      @config = Config.new
      @config.instance_eval(&block)
      @config.apply_environment_settings!

      AWS::S3::Base.establish_connection!(
        access_key_id: config.access_key_id,
        secret_access_key: config.secret_access_key
      )
    end

    def deploy!
      config.before_deploy if config.before_deploy
      copy_files_to_s3
      config.after_deploy if config.after_deploy
    end

    private

    def copy_files_to_s3()
      dir = File.join(app_path_with_bucket, rev)
      source_files_list.each do |file|
        s3_file_dir = Pathname.new(
          File.dirname(file)).relative_path_from(
            Pathname.new(config.dist_dir)).to_s
        absolute_s3_file_dir = s3_file_dir == '.' ? dir : File.join(dir, s3_file_dir)
        store_value(
          File.basename(file), File.read(file), absolute_s3_file_dir)
      end
    end

    def app_path_with_bucket
      File.join(config.bucket, config.app_path)
    end

    def get_value(key, path)
      puts "Retrieving value #{key} from #{path} on S3"
      AWS::S3::S3Object.value(key, path)
    end

    def should_compress?(key)
      if [true, false, nil].include?(config.gzip)
        !!config.gzip
      else
        key != Array(config.gzip).any? { |regexp| key.match(regexp) }
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

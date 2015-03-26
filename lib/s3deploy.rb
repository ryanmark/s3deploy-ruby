require 's3deploy/config'
require 's3deploy/deployer'

# Top level module for s3deploy, also a singleton instance of a Deployer
module S3deploy
  DEFAULT_GZIP = [
    /\.js$/, /\.css$/, /\.html?$/, /\.svg$/, /\.md$/,
    /\.json$/, /\.csv$/, /\.tsv$/,
    /\.eot$/, /\.ttf$/, /\.woff$/
  ]
  class << self
    attr_reader :config
    def configure(&block)
      @config = Config.new
      @config.instance_eval(&block)
      @config.apply_environment_settings!

      @deployer = Deployer.new(
        access_key_id: config.access_key_id,
        secret_access_key: config.secret_access_key,
        dist_dir: config.dist_dir,
        bucket: config.bucket,
        app_path: config.app_path,
        gzip: config.gzip,
        logger: config.logger
      )
    end

    def deploy!
      config.before_deploy if config.before_deploy
      @deployer.deploy!
      config.after_deploy if config.after_deploy
    end
  end
end

require 's3deploy/config'
require 's3deploy/deployer'

# Top level module for s3deploy, also a singleton instance of a Deployer
module S3deploy
  DEFAULT_GZIP = [
    /\.js$/, /\.css$/, /\.html?$/, /\.svg$/, /\.md$/, /\.txt$/,
    /\.json$/, /\.topojson$/, /\.geojson$/, /\.kml$/,
    /\.csv$/, /\.tsv$/,
    /\.eot$/, /\.ttf$/, /\.woff$/
  ]
  class << self
    def configure(&block)
      config.instance_eval(&block)
      config.apply_environment_settings!

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

    def config
      @config ||= Config.new
    end

    def deploy!
      config.before_deploy.call if config.before_deploy.respond_to?(:call)
      @deployer.deploy!
      config.after_deploy.call if config.after_deploy.respond_to?(:call)
    end

    def destroy!
      @deployer.delete!
    end

    def new(opts)
      Deployer.new(opts)
    end
  end
end

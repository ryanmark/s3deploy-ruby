module S3deploy
  # Settings for a deploy
  class Config
    attr_reader :env

    def initialize
      @env = ENV['ENV'] || 'staging'
      @env_settings = {}
    end

    %w(
      bucket app_path dist_dir access_key_id secret_access_key gzip
      before_deploy after_deploy logger metadata acl cache_control exclude
    ).each do |method|
      define_method method do |value = :omitted|
        instance_variable_set("@#{method}", value) unless value == :omitted
        instance_variable_get("@#{method}")
      end
    end

    def environment(name, &block)
      @env_settings[name.to_s] = block
    end

    def apply_environment_settings!
      instance_eval(&@env_settings[@env.to_s]) if @env_settings[@env.to_s]
    end
  end
end

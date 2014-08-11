# S3deploy

Rake tasks for pushing stuff to S3. Heavily cribbed from [Mixbook's S3 Deployer](https://github.com/Mixbook/s3_deployer). Unlike Mixbook's thing, this does no versioning or fancy revisiony stuff. Eventually needs to invalidate CloudFront.

## Installation

Add this line to your application's Gemfile:

    gem 's3deploy', git: 'https://github.com/ryanmark/s3deploy-ruby.git'

And then execute:

    $ bundle

## Usage

Your Rakefile should look something like this:

```ruby
require 'rubygems'
require 'bundler'
Bundler.setup

require 's3deploy/tasks'

S3deploy.configure do
  bucket "my-staging-bucket"
  app_path "devastator" # dir in the S3 bucket to deploy to
  dist_dir "dist" # local dir to deploy from
  gzip [/\.js$/, /\.css$/, /\.json$/, /\.html$/, /\.csv$/] # or just use 'true' to gzip everything

  before_deploy ->(version) do
    # Some custom code to execute before deploy
  end

  after_deploy ->(version) do
    # Some custom code to execute after deploy
  end

  # You also can specify environment-specific settings, the default environment is 'production'
  environment(:production) do
    bucket "my-production-bucket"
  end

  access_key_id ENV['AWS_ACCESS_KEY_ID']
  secret_access_key ENV['AWS_SECRET_ACCESS_KEY']
end
```

To actually deploy:

    $ rake s3:deploy

To deploy to production:

    $ ENV=production rake s3:deploy

## Contributing

1. Fork it ( https://github.com/ryanmark/s3deploy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

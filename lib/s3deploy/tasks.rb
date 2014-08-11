require 's3deploy'

namespace :s3 do
  desc 'Deploy this project to S3'
  task :deploy do
    s3deploy.deploy!
  end
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 's3deploy/version'

Gem::Specification.new do |spec|
  spec.name          = 's3deploy'
  spec.version       = S3deploy::VERSION
  spec.authors       = ['Ryan Mark']
  spec.email         = ['ryan@mrk.cc']
  spec.summary       = %q(Rake task for deploying to S3)
  spec.homepage      = 'https://github.com/ryanmark/s3deploy-ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk'
  spec.add_dependency 'mime-types'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
end

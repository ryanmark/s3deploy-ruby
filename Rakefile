require 'bundler/gem_tasks'
require 'rake/testtask'
require 'dotenv/tasks'

Rake::TestTask.new(test: :dotenv) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/*/test_*.rb']
end

task default: :test

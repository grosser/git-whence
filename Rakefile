require "bundler/setup"
require "bundler/gem_tasks"

require "rake/testtask"
Rake::TestTask.new :default do |t|
  t.pattern = 'test/**/*_test.rb'
  t.warning = false
end

# release a static binary and link it from the readme
require "rubinjam/tasks"
require "bump/tasks"
task release: 'rubinjam:upload_binary'
Bump.replace_in_default = ["Readme.md"]

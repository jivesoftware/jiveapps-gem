require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/jiveapps'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'jiveapps' do
  self.developer 'Scott Becker', 'becker.scott@gmail.com'
  self.description          = "A set of command line tools for creating Jive Apps."
  self.summary              = self.description
  self.version              = "0.0.4"
  self.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
  self.rubyforge_name       = self.name # TODO this is default value
  self.extra_deps           = [
    ['rest-client'],
    ['json'],
    ['rubigen']
  ]
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]



### gems this gem depends on
# rest_client
# json_pure (or json)
# rubigen
# rspec (2.0.0.rc)
# webmock 1.4.0 (for development/testing)

################

require 'rake'
require 'rspec'
require 'rspec/core/rake_task'

desc "Run all specs"
RSpec::Core::RakeTask.new('spec') do |t|
  t.rspec_opts = ['--colour --format progress']
#  t.spec_files = FileList['spec/**/*_spec.rb']
end

desc "Print specdocs"
RSpec::Core::RakeTask.new(:doc) do |t|
  t.rspec_opts = ["--format", "specdoc", "--dry-run"]
#  t.spec_files = FileList['spec/*_spec.rb']
end

desc "Generate RCov code coverage report"
RSpec::Core::RakeTask.new('rcov') do |t|
#  t.spec_files = FileList['spec/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'examples']
end

task :default => :spec

$LOAD_PATH << './lib'

require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require 'jiveapps'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'jiveapps' do
  self.developer 'Scott Becker', 'becker.scott@gmail.com'
  self.version              = "0.0.6"
  self.rubyforge_name       = self.name # TODO this is default value
  self.extra_rdoc_files << 'README.rdoc'
  self.extra_deps           = [
    ['activesupport', '2.3.5'],
    ['rest-client', '1.6.1'],
    ['rubigen', '1.5.5']
  ]
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]

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

desc "Fix password"
task "fix_pass" do
  system "rm ~/.jiveapps/credentials"
  system "cp ~/.jiveapps/credentials_right ~/.jiveapps/credentials"
end

desc "Break password"
task "break_pass" do
  system "rm ~/.jiveapps/credentials"
  system "cp ~/.jiveapps/credentials_wrong ~/.jiveapps/credentials"
end

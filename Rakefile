require 'bundler'
Bundler::GemHelper.install_tasks

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
  t.pattern = 'spec/**/*_spec.rb'
  t.rcov = true
  t.rcov_opts = ['--exclude', '/Library,spec']
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

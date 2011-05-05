Autotest.add_discovery { "rspec2" }

# Run RCov after every autotest run
require 'autotest/rcov'
Autotest::RCov.command = 'rcov'
Autotest::RCov.options = ['--exclude', '/Library,spec']

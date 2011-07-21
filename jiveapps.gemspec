# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "jiveapps/version"

Gem::Specification.new do |s|
  s.name        = "jiveapps"
  s.version     = Jiveapps::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Scott Becker"]
  s.email       = ["becker.scott@gmail.com"]
  s.homepage    = "https://github.com/jivesoftware/jiveapps-gem"
  s.summary     = %q{The "jiveapps" gem is a set of command line tools for building and hosting Jive App front-ends.}
  s.description = %q{== Jiveapps

These tools are all about making Jive App development as easy as possible. After you install the tools, it only takes a single command to:

1. Create a new app - a simple Hello World application.
2. Set up version control for your code using Git.
3. Host the app code online at Jive's AppHosting server.
4. Register the app on the Jive Apps Marketplace as an app "in development".
5. Install the app on your default app dashboard in the Jive Apps Sandbox.

After you install, use this simple workflow to make changes and see them reflected in the sandbox:

1. Make a change to the code on your local machine.
2. Commit the changes to your local Git repository.
3. Push the changes to the remote Jive Apps repository. This automatically updates the hosted copy on the Jive AppHosting server.
4. Refresh the app dashboard or canvas page on the Jive Apps Sandbox and see your changes.

Other features:

* LiveDev: preview your changes on the Jive App Sandbox in real time
* Collaboration: add other developers to your project
* OAuth Key Management: associate consumer key/secret pairs with service names for use in your apps

}

  s.add_dependency 'activesupport',     '2.3.5'
  s.add_dependency 'directory_watcher', '1.3.2'
  s.add_dependency 'rest-client',       '1.6.1'
  s.add_dependency 'rubigen',           '1.5.5'
  s.add_dependency 'systemu',           '2.2.0'

  s.add_development_dependency 'rspec',   '>= 2.2.0'
  s.add_development_dependency 'rcov',    '>= 0.9.9'
  s.add_development_dependency 'webmock', '>= 1.6.1'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

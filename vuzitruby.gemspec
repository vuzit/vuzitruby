# -*- encoding: utf-8 -*-
#
# Gem building script for Github.  Every time the version is updated the 
# gem will be built.

# Gem building task
Gem::Specification.new do |s|
  s.name = 'vuzitruby'
  s.version = "2.1.0"
  s.homepage = 'http://wiki.github.com/vuzit/vuzitruby/'
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brent Matzelle"]
  s.default_executable = %q{vuzitcl}
  s.executables = ["vuzitcl"]
  s.date = %q{2010-03-01}
  s.description = %q{Code library that allows developers to directly access 
                     the Vuzit Document Viewer Web Service API through Ruby.}
  s.email = %q{support@vuzit.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["README", "Rakefile", "lib/vuzitruby.rb","lib/vuzitruby/base.rb", 
             "lib/vuzitruby/document.rb", "lib/vuzitruby/client_exception.rb", 
             "lib/vuzitruby/service.rb"]
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{vuzitruby}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Ruby client library for the Vuzit Web Services API}
end


require 'rubygems'
#require 'hoe'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.name = 'vuzitruby'
  s.author = 'Brent Matzelle'
  s.email = 'support@vuzit.com'
  s.homepage = "http://vuzit.com/"
  s.summary = 'Ruby client library for the Vuzit API'
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
end

#Rake::GemPackageTask.new(spec) do |pkg| 
  #pkg.need_tar = true 
#end 

namespace :github do
  desc "Prepare for GitHub gem packaging"
  task :prepare do
    `rake debug_gem > vuzitruby.gemspec`
  end
end


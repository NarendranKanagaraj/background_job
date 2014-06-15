$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "background_job/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "background_job"
  s.version     = BackgroundJob::VERSION
  s.authors     = ["Narendran Kanagaraj"]
  s.email       = ["kevin007.k@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of BackgroundJob."
  s.description = "TODO: Description of BackgroundJob."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.12"

  s.add_development_dependency "sqlite3"
end

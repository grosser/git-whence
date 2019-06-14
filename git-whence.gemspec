name = "git-whence"
$LOAD_PATH << File.expand_path("../lib", __FILE__)
require "#{name.gsub("-","/")}/version"

Gem::Specification.new name, Git::Whence::VERSION do |s|
  s.summary = "Find the merge and pull request a commit came from + find cherry-picks"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib/ bin/ MIT-LICENSE`.split("\n")
  s.license = "MIT"
  s.executables = ["git-whence"]
  s.required_ruby_version = '>= 2.3'
end

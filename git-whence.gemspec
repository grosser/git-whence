name = "git-whence"
require "./lib/#{name.gsub("-","/")}/version"

Gem::Specification.new name, Git::Whence::VERSION do |s|
  s.summary = "Find the merge and pull request a commit came from + find cherry-picks"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib/ bin/ MIT-LICENSE`.split("\n")
  s.license = "MIT"
  cert = File.expand_path("~/.ssh/gem-private-key-grosser.pem")
  if File.exist?(cert)
    s.signing_key = cert
    s.cert_chain = ["gem-public_cert.pem"]
  end
end

require "spec_helper"

describe Git::Whence do
  it "has a VERSION" do
    Git::Whence::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe "CLI" do
    around do |example|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir, &example)
      end
    end

    it "shows --version" do
      whence("--version").should include(Git::Whence::VERSION)
    end

    it "shows --help" do
      whence("--help").should include("cherry-picks")
    end

    it "fails without git" do
      whence("ssdfsfdfd", :fail => true).should include "Not in a git directory\n"
    end

    it "finds a simple merge" do
      init_git
      merge, commit = add_merge
      whence(commit).should == "#{merge} Merge branch 'foobar'\n"
    end

    it "finds a simple merge on a non-master branch" do
      init_git
      sh("git checkout -b production")
      merge, commit = add_merge :branch => "production"
      sh("git checkout production")
      whence(commit).should == "#{merge} Merge branch 'foobar' into production\n"
    end

    it "finds a simple master merge on a non-master branch" do
      init_git
      merge, commit = add_merge
      sh("git checkout -b production")
      whence(commit).should == "#{merge} Merge branch 'foobar'\n"
    end
  end

  def write(file, content)
    File.open(file, "w") { |f| f.write content }
  end

  def whence(command, options={})
    sh("#{Bundler.root}/bin/git-whence #{command}", options)
  end

  def sh(command, options={})
    result = `#{command} #{"2>&1" unless options[:keep_output]}`
    raise "#{options[:fail] ? "SUCCESS" : "FAIL"} #{command}\n#{result}" if $?.success? == !!options[:fail]
    result
  end

  def init_git
    write "xxx", "xxx"
    sh("git init && git add -A")
    sh("git commit -am 'initial'")
  end

  def add_merge(options={})
    sh("git co -b foobar 2>&1 && git commit -m 'xxx' --allow-empty && git checkout #{options[:branch] || "master"} 2>&1 && git merge foobar --no-ff")
    commits = sh("git log --pretty=format:'%h' | head -3").split("\n")
    return commits[0], commits[2]
  end
end

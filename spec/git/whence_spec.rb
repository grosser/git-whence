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

    it "fails without commit" do
      init_git
      whence("1231231231", :fail => true).should include "unknown revision or path not in the working"
    end

    # cannot be tested via cli because it opens the browser
    context "-o" do
      before do
        init_git
        sh("git remote add origin git@github.com:foobar/barbaz.git")
        _, @commit = add_merge :message => "Merge pull request #10486 from foo/baz"
      end

      it "opens with -o" do
        Git::Whence::CLI.should_receive(:exec).with("open", "https://github.com/foobar/barbaz/pull/10486")
        Git::Whence::CLI.run([@commit, "-o"])
      end

      # TODO: this prints to stderr :(
      it "fails when unable to find origin" do
        sh("git remote rm origin")
        Git::Whence::CLI.should_not_receive(:exec)
        -> { Git::Whence::CLI.run([@commit, "-o"]) }.should raise_error(RuntimeError)
      end

      it "opens commit when PR is unfindable" do
        merge, @commit = add_merge :message => "Nope", :branch => "foobaz"
        Git::Whence::CLI.should_receive(:warn)
        Git::Whence::CLI.should_receive(:exec).with("open", "https://github.com/foobar/barbaz/commit/#{merge}")
        Git::Whence::CLI.run([@commit, "-o"])
      end
    end

    context "simple find" do
      it "finds a simple merge" do
        init_git
        merge, commit = add_merge
        whence(commit).should == "#{merge[0...7]} Merge branch 'foobar'\n"
      end

      it "finds a simple merge from short commit" do
        init_git
        merge, commit = add_merge
        whence(commit[0...6]).should == "#{merge[0...7]} Merge branch 'foobar'\n"
      end

      it "finds a simple merge on a non-master branch" do
        init_git
        sh("git checkout -b production")
        merge, commit = add_merge :base => "production"
        sh("git checkout production")
        whence(commit).should == "#{merge[0...7]} Merge branch 'foobar' into production\n"
      end

      it "finds a simple master merge on a non-master branch" do
        init_git
        merge, commit = add_merge
        sh("git checkout -b production")
        whence(commit).should == "#{merge[0...7]} Merge branch 'foobar'\n"
      end

      it "fails with a mainline commit" do
        init_git
        3.times { |i| sh("echo #{i} > xxx && git commit -am 'xxx#{i}'") }
        result = whence(last_commits[2], :fail => true)
        result.should == "Unable to find merge\n"
      end

      it "fails with a mainline commit after a merge" do
        init_git
        sh("echo 1 > xxx && git commit -am 'xxx1'")
        commit = last_commits[0]
        add_merge
        result = whence(commit, :fail => true)
        result.should == "Unable to find merge\n"
      end
    end

    context "fuzzy find" do
      before do
        init_git
        @merge, commit = add_merge
        pick_commit(commit)
      end

      it "finds by commit message" do
        whence("HEAD").should == "#{@merge[0...7]} Merge branch 'foobar'\n"
      end

      it "does not find from different author" do
        sh "git commit --amend -C HEAD --author 'New Author Name <email@address.com>'"
        whence("HEAD", :fail => true)
      end
    end

    context "merge find" do
      it "finds a direct merge" do
        init_git
        merge, commit = add_merge
        whence(merge, :fail => true).should == "Commit is a merge\n#{merge[0...7]} Merge branch 'foobar'\n"
      end
    end
  end

  def last_commits
    sh("git log --pretty=format:'%H' | head").split("\n")
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
    if message = options[:message]
      message = "-m '#{message}'"
    end
    branch = options[:branch] || "foobar"
    base = options[:base] || "master"
    sh("git checkout -b #{branch} 2>&1 && echo asd >> xxx && git commit -am 'xxx' && git checkout #{base} 2>&1 && git merge #{branch} --no-ff #{message}")
    commits = last_commits
    return commits[0], commits[2]
  end

  def pick_commit(commit)
    sh("git checkout HEAD^ 2>&1 && git checkout -b production 2>&1 && git cherry-pick #{commit}")
  end
end

require "git/whence/version"
require "optparse"

module Git::Whence
  module CLI
    SQUASH_REGEX = /\(#(\d+)\)$/
    DEFAULT_BRANCHES = ["main", "master"]

    class << self
      def run(argv)
        options = parse_options(argv)
        commit = argv[0]
        unless system("git rev-parse --git-dir 2>&1 >/dev/null")
          warn "Not in a git directory"
          return 1
        end

        commit = expand(commit)

        if is_merge?(commit)
          warn "Commit is a merge"
          show_commit(commit, options)
          1
        else
          if merge = find_merge(commit)
            show_commit(merge, options)
            0
          else
            warn "Unable to find merge"
            show_commit(commit, options) if options[:open]
            1
          end
        end
      end

      private

      def expand(commit)
        sh("git rev-parse #{commit}").strip
      end

      def is_merge?(commit)
        sh("git cat-file -p #{commit}").split("\n")[1..2].grep(/parent /).size > 1
      end

      def show_commit(merge, options)
        info = sh("git show -s --oneline #{merge}").strip
        if options[:open]
          if pr = info[/Merge pull request #(\d+) from /, 1] || info[SQUASH_REGEX, 1]
            exec "open", "https://github.com/#{origin}/pull/#{pr}"
          else
            warn "Unable to find PR number in #{info}"
            exec "open", "https://github.com/#{origin}/commit/#{merge}"
          end
        else
          puts info
        end
      end

      # https://github.com/foo/bar or git@github.com:foo/bar.git -> foo/bar
      def origin
        repo = sh("git remote get-url origin").strip # TODO: read file instead
        repo.sub!(/\.git$/, "")
        repo.split(/[:\/]/).last(2).join("/")
      end

      def find_merge(commit)
        merge_commit, merge = (
          find_merge_simple(commit, "HEAD") ||
          find_merge_simple(commit, default_branch) ||
          find_merge_fuzzy(commit, default_branch)
        )

        if merge && merge_include_commit?(merge, merge_commit)
          merge
        else
          find_squash_merge(commit) # not very exact, so do this last ... ideally ask github api
        end
      end

      def merge_include_commit?(merge, commit)
        commit = sh("git show HEAD -s --format=%H").strip if commit == "HEAD"
        sh("git log #{merge.strip}^..#{merge.strip} --pretty=%H").split("\n").include?(commit)
      end

      def find_merge_fuzzy(commit, branch)
        if (similar = find_similar(commit, branch))
          find_merge_simple(similar, branch)
        end
      end

      def default_branch
        @default_branch ||= remote_default_branch || local_default_branch
      end

      def remote_default_branch
        remotes = sh("git remote").split("\n")
        return nil if remotes.empty?
        preferred = (remotes.include?("origin") ? "origin" : remotes.first)
        folder = ".git/refs/remotes/#{preferred}"
        (Dir["#{folder}/*"].map { |f| f.sub("#{folder}/", "") } & DEFAULT_BRANCHES).sort.first
      end

      # guess default branch by last changed commonly used default branch or current branch
      def local_default_branch
        branches = sh("git branch --sort=-committerdate").split("\n").map { |br| br.split(" ").last }
        (branches & DEFAULT_BRANCHES).first || sh("git symbolic-ref HEAD").strip.sub("refs/heads/", "")
      end

      def find_squash_merge(commit)
        commit if sh("git show -s --format='%s' #{commit}") =~ SQUASH_REGEX
      end

      def find_similar(commit, branch)
        month = 30 * 24 * 60 * 60
        time, search = sh("git show -s --format='%ct %an %s' #{commit}").strip.split(" ", 2)
        time = time.to_i
        same = sh("git log #{branch} --pretty=format:'%H %an %s' --before #{time + month} --after #{time - month}")
        found = same.split("\n").map { |x| x.split(" ", 2) }.detect { |_, message| message == search }
        found&.first
      end

      def find_merge_simple(commit, branch)
        result = sh("git log #{commit}..#{branch} --ancestry-path --merges --pretty='%H' 2>/dev/null | tail -n 1").chomp
        [commit, result] unless result.empty?
      end

      def sh(command)
        result = `#{command}`
        raise "Command failed\n#{command}\n#{result}" unless $?.success?
        result
      end

      def parse_options(argv)
        options = {}
        OptionParser.new do |opts|
          opts.banner = <<-BANNER.gsub(/^ {10}/, "")
            Find the merge and pull request a commit came from, also finding straight cherry-picks.

            Usage:
                git-whence <sha>

            Options:
          BANNER
          opts.on("-o", "--open", "Open PR in github") { options[:open] = true }
          opts.on("-h", "--help", "Show this.") { puts opts; exit }
          opts.on("-v", "--version", "Show Version"){ puts Git::Whence::VERSION; exit}
        end.parse!(argv)

        raise "just 1 commit plz" if argv.size != 1

        options
      end
    end
  end
end

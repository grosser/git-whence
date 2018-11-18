require "git/whence/version"
require "optparse"

module Git::Whence
  module CLI
    class << self
      def run(argv)
        options = parse_options(argv)
        commit = argv[0]
        unless system("git rev-parse --git-dir 2>&1 >/dev/null")
          puts "Not in a git directory"
          return 1
        end

        commit = expand(commit)

        if is_merge?(commit)
          $stderr.puts "Commit is a merge"
          finished_with_commit(commit, options)
          1
        else
          merge = find_merge(commit)
          if merge
            finished_with_commit(merge, options)
            0
          else
            $stderr.puts "Unable to find merge"
            1
          end
        end
      end

      private

      def expand(commit)
        sh("git show #{commit} -s --format='%H'").strip
      end

      def is_merge?(commit)
        sh("git cat-file -p #{commit}").split("\n")[1..2].grep(/parent /).size > 1
      end

      def finished_with_commit(merge, options)
        info = sh("git show -s --oneline #{merge}").strip
        if options[:open] && (pr = info[/Merge pull request #(\d+) from /, 1]) && (url = origin)
          repo = url[%r{(\w+/[-\w\.]+)}i, 1].to_s.sub(/\.git$/, "")
          exec "open", "https://github.com/#{repo}/pull/#{pr}"
        else
          puts info
        end
      end

      def origin
        remotes = sh("git remote -v").split("\n")
        remotes.detect { |l| l.start_with?("origin\t") }.split(" ")[1]
      end

      def find_merge(commit)
        commit, merge = find_merge_simple(commit, "HEAD") ||
          find_merge_simple(commit, "master") ||
          find_merge_fuzzy(commit, "master")

        merge if merge && merge_include_commit?(merge, commit)
      end

      def merge_include_commit?(merge, commit)
        commit = sh("git show HEAD -s --format=%H").strip if commit == "HEAD"
        sh("git log #{merge.strip}^..#{merge.strip} --pretty=%H").split("\n").include?(commit)
      end

      def find_merge_fuzzy(commit, branch)
        if similar = find_similar(commit, branch)
          find_merge_simple(similar, branch)
        end
      end

      def find_similar(commit, branch)
        month = 30 * 24 * 60 * 60
        time, search = sh("git show -s --format='%ct %an %s' #{commit}").strip.split(" ", 2)
        time = time.to_i
        same = sh("git log #{branch} --pretty=format:'%H %an %s' --before #{time + month} --after #{time - month}")
        found = same.split("\n").map { |x| x.split(" ", 2) }.detect { |commit, message| message == search }
        found && found.first
      end

      def find_merge_simple(commit, branch)
        result = sh "git log #{commit}..#{branch} --ancestry-path --merges --pretty='%H' 2>/dev/null | tail -n 1"
        [commit, result] unless result.strip.empty?
      end

      def sh(command)
        result = `#{command}`
        raise unless $?.success?
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

require "git/whence/version"
require "optparse"

module Git::Whence
  module CLI
    class << self
      def run(argv)
        options = parse_options(argv)
        commit = argv[0]
        unless system("git rev-parse --git-dir 1>&2>/dev/null")
          puts "Not in a git directory"
          return 1
        end

        simple = find_merge(commit, "HEAD") || find_merge(commit, "master")
        if simple
          puts simple
          0
        else
          $stderr.puts "Unable to find commit"
          1
        end
      end

      private

      def find_merge(commit, branch)
        result = sh "git log #{commit}..#{branch} --ancestry-path --merges --oneline 2>/dev/null | tail -n 1"
        result unless result.strip.empty?
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

require File.expand_path(File.join(File.dirname(__FILE__), 'base'))

class GitHubPostReciever
  module Worker
    class Simple < Base
      def run method, json
        p method
        p json
      end
    end
  end
end

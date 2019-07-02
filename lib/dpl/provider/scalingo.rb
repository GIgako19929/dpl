require 'net/http'
require 'uri'
require 'json'
require 'date'

module DPL
  class Provider
    class Scalingo < Provider
      def install_deploy_dependencies
        if !context.shell 'curl -OL https://cli-dl.scalingo.io/release/scalingo_latest_linux_amd64.tar.gz && tar -zxvf scalingo_latest_linux_amd64.tar.gz && mv scalingo_*_linux_amd64/scalingo . && rm scalingo_latest_linux_amd64.tar.gz && rm -r scalingo_*_linux_amd64'
          error "Couldn't install Scalingo CLI."
        end
      end

      def initialize(context, options)
        super
        @options = options
        @remote = options[:remote] || 'scalingo'
        @branch = options[:branch] || 'master'
      end

      def logged_in
        context.shell 'DISABLE_INTERACTIVE=true ./scalingo login > /dev/null'
      end

      def check_auth
        token = @options[:api_key] || @options[:api_token]
        if token
          context.shell "timeout 2 ./scalingo login --api-token #{token} > /dev/null"
        elsif @options[:username] && @options[:password]
          context.shell "echo -e \"#{@options[:username]}\n#{@options[:password]}\" | timeout 2 ./scalingo login > /dev/null"
        end
        error "Couldn't connect to Scalingo API." if !logged_in
      end

      def setup_key(file, _type = nil)
        error "Couldn't connect to Scalingo API." if !logged_in
        error "Couldn't add ssh key." if !context.shell "./scalingo keys-add dpl_tmp_key #{file}"
      end

      def remove_key
        error "Couldn't connect to Scalingo API." if !logged_in
        error "Couldn't remove ssh key." if !context.shell './scalingo keys-remove dpl_tmp_key'
      end

      def push_app
        if @options[:app]
          context.shell "git remote add #{@remote} git@scalingo.com:#{@options[:app]}.git > /dev/null"
        end
        error "Couldn't push your app." if !context.shell "git push #{@remote} #{@branch} -f"
      end
    end
  end
end

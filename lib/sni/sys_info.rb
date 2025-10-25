module Sni
  class SysInfo
    def self.call
      new.call
    end

    def call
      {
        host: hostname,
        env: rails_environment,
        ruby: ruby_version,
        rails: rails_version,
        gem: gem_version,
        bundler: bundler_version,
        server: server_version,
        postgres: postgres_version,
        user: user,
        shell: shell,
        pwd: pwd,
        path: path
      }
    end

    private

    def hostname
      ENV["HOSTNAME"] || `hostname`.chomp.sub(".local", "")
    rescue => e
      log_warning("Failed to get hostname: #{e.message}")
      "unknown"
    end

    def rails_environment
      return "N/A" unless defined?(Rails)
      Rails.env.to_s
    end

    def ruby_version
      RUBY_VERSION
    end

    def rails_version
      return "N/A" unless defined?(Rails)
      Rails.version
    end

    def gem_version
      `gem -v`.scan(/\d+\.\d+\.\d+/).first || "unexpected format"
    rescue => e
      log_warning("Failed to get gem version: #{e.message}")
      "unknown"
    end

    # note: ENV["BUNDLER_VERSION"] could be used here instead
    def bundler_version
      `bundler -v`.scan(/\d+\.\d+\.\d+/).first || "unexpected format"
    rescue => e
      log_warning("Failed to get bundler version: #{e.message}")
      "unknown"
    end

    def server_version
      if production_environment?
        passenger_version
      elsif development_environment?
        puma_version
      else
        "N/A"
      end
    end

    def passenger_version
      version = `env -i /usr/bin/passenger-config --version`.scan(/\d+\.\d+\.\d+/).first
      version ? "Passenger #{version}" : "unexpected format"
    rescue => e
      log_warning("Failed to get Passenger version: #{e.message}")
      "unknown"
    end

    def puma_version
      return "N/A" unless defined?(Puma)
      "Puma #{Puma::Const::VERSION}"
    rescue => e
      log_warning("Failed to get Puma version: #{e.message}")
      "unknown"
    end

    def postgres_version
      return "N/A" unless defined?(ActiveRecord)
      version = ActiveRecord::Base.connection.execute('select version();').values[0][0]
      version.match(/PostgreSQL (\d+\.\d+)/) ? $1 : "unexpected format"
    rescue => e
      log_warning("Failed to get PostgreSQL version: #{e.message}")
      "unknown"
    end

    def user
      ENV["USER"] || "unknown"
    end

    def shell
      ENV["SHELL"] || "unknown"
    end

    def pwd
      ENV["PWD"] || "unknown"
    end

    def path
      return "unknown" unless ENV["PATH"]
      ENV["PATH"].split(":").map { |p| simplify_home_path(p) }.join(", ")
    rescue => e
      log_warning("Failed to get path: #{e.message}")
      "unknown"
    end

    def simplify_home_path(path)
      if path =~ %r{^/Users/\w+(/.*)?$}
        path.sub(%r{^/Users/\w+}, "~")
      elsif path =~ %r{^/home/\w+(/.*)?$}
        path.sub(%r{^/home/\w+}, "~")
      else
        path
      end
    end

    def production_environment? = defined?(Rails) && Rails.env.production?
    def development_environment? = defined?(Rails) && Rails.env.development?

    def log_warning(message)
      if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        Rails.logger.warn(message)
      end
    end
  end
end

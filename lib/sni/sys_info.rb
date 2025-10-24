module Sni
  class SysInfo
    def self.call
      new.call
    end

    def call
      {
        host: hostname,
        ruby_version: ruby_version,
        rails_version: rails_version,
        gem_version: gem_version,
        server_version: server_version,
        environment: rails_environment
      }
    end

    private

    def hostname
      ENV["HOSTNAME"] || `hostname`.chomp.sub(".local", "")
    rescue => e
      log_warning("Failed to get hostname: #{e.message}")
      "unknown"
    end

    def ruby_version
      RUBY_VERSION
    end

    def rails_version
      return "N/A" unless defined?(Rails)
      Rails.version
    end

    def gem_version
      `gem -v`.strip
    rescue => e
      log_warning("Failed to get gem version: #{e.message}")
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
      return nil unless production_environment?
      `env -i /usr/bin/passenger-config --version`.scan(/\d+\.\d+\.\d+/).first
    rescue => e
      log_warning("Failed to get Passenger version: #{e.message}")
      "unknown"
    end

    def puma_version
      return nil unless development_environment?
      return "N/A" unless defined?(Puma)
      Puma::Const::VERSION
    rescue => e
      log_warning("Failed to get Puma version: #{e.message}")
      "unknown"
    end

    def rails_environment
      return "N/A" unless defined?(Rails)
      Rails.env.to_s
    end

    def production_environment?
      defined?(Rails) && Rails.env.production?
    end

    def development_environment?
      defined?(Rails) && Rails.env.development?
    end

    def log_warning(message)
      if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        Rails.logger.warn(message)
      end
    end
  end
end

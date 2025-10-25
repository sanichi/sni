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
      paths = ENV["PATH"].split(":")
      compress_paths(paths)
    rescue => e
      log_warning("Failed to get path: #{e.message}")
      "unknown"
    end

    def compress_paths(paths)
      return "" if paths.empty?
      return paths.first if paths.length == 1

      # Group paths by common prefixes
      grouped = group_by_prefix(paths)

      # Convert to brace expansion format
      grouped.map do |prefix, suffixes|
        if suffixes.length == 1 && suffixes.first.empty?
          prefix
        elsif suffixes.length == 1
          "#{prefix}/#{suffixes.first}"
        else
          clean_suffixes = suffixes.map { |s| s.empty? ? "" : s }
          if clean_suffixes.include?("")
            others = clean_suffixes.reject(&:empty?)
            if others.empty?
              prefix
            else
              "#{prefix}{,/#{others.join(",/")}}"
            end
          else
            "#{prefix}/{#{clean_suffixes.join(",")}}"
          end
        end
      end.join(", ")
    end

    def group_by_prefix(paths)
      return { "" => paths } if paths.empty?

      # Find common prefix
      first_parts = paths.first.split("/")
      common_prefix_length = 0

      first_parts.each_with_index do |part, index|
        if paths.all? { |path| path.split("/")[index] == part }
          common_prefix_length = index + 1
        else
          break
        end
      end

      if common_prefix_length == 0
        # No common prefix, group by first component
        groups = {}
        paths.each do |path|
          parts = path.split("/")
          first = parts.first || ""
          rest = parts[1..-1]&.join("/") || ""
          groups[first] ||= []
          groups[first] << rest
        end
        return groups
      else
        # Has common prefix
        common = first_parts[0...common_prefix_length].join("/")
        suffixes = paths.map do |path|
          parts = path.split("/")
          parts[common_prefix_length..-1]&.join("/") || ""
        end

        if suffixes.all?(&:empty?)
          return { common => [""] }
        else
          # Recursively group the suffixes
          suffix_groups = group_by_prefix(suffixes.reject(&:empty?))
          if suffixes.include?("")
            # Add empty suffix for the common prefix itself
            suffix_groups[""] = [""]
          end

          result = {}
          suffix_groups.each do |suffix_prefix, suffix_list|
            full_prefix = suffix_prefix.empty? ? common : "#{common}/#{suffix_prefix}"
            result[full_prefix] = suffix_list
          end
          return result
        end
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

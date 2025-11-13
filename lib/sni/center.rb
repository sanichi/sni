# frozen_string_literal: true

module Sni
  class Center
    BP = %w/xs sm md lg xl xxl/.map(&:to_sym)

    def self.call(args = {})
      new(args).call
    end

    def initialize(args)
      raise "invalid input" unless args.is_a?(Hash)
      @breakpoints = extract_breakpoints(args)
    end

    def call
      return "col-12" if @breakpoints.empty?
      @breakpoints.map { |bp, width| bootstrap_classes(bp, width) }.join(" ")
    end

    private

    def extract_breakpoints(args)
      bps = {}
      BP.each do |bp|
        key = bp == :xxl ? :xx : bp
        width = args[key].to_i
        bps[bp] = width if width > 0
      end
      bps
    end

    def bootstrap_classes(bp, width)
      offset = (12 - width) / 2
      if bp == :xs
        "offset-#{offset} col-#{width}"
      else
        "offset-#{bp}-#{offset} col-#{bp}-#{width}"
      end
    end
  end
end

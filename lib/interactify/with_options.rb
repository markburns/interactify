# frozen_string_literal: true

require "interactify/core"
require "interactify/async/jobable"

module Interactify
  class WithOptions
    def initialize(receiver, sidekiq_opts = {})
      @receiver = receiver
      @options = sidekiq_opts.transform_keys(&:to_sym)
    end

    def setup
      validate_options

      this = self

      @receiver.instance_eval do
        include Interactify::Core
        include Interactify::Async::Jobable
        interactor_job(opts: this.options, klass_suffix: this.klass_suffix)

        # define aliases when the generate class name differs.
        # i.e. when options are passed
        if this.klass_suffix.present?
          const_set("Job", const_get(:"Job#{this.klass_suffix}"))
          const_set("Async", const_get(:"Async#{this.klass_suffix}"))
        end
      end
    end

    attr_reader :options

    def klass_suffix
      @klass_suffix ||= options.keys.sort.map do |key|
        "__#{key.to_s.camelize}_#{options[key].to_s.camelize}"
      end.join
    end

    private

    def validate_options
      return if invalid_keys.none?

      raise ArgumentError, "Invalid keys: #{invalid_keys}"
    end

    def invalid_keys
      options.keys - Interactify::Async::JobMaker::VALID_KEYS
    end
  end
end

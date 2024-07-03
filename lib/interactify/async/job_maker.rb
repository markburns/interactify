# frozen_string_literal: true

require "interactify/async/job_klass"

module Interactify
  module Async
    class JobMaker
      VALID_KEYS = %i[queue retry dead backtrace pool tags].freeze
      attr_reader :opts, :method_name, :container_klass, :klass_suffix

      def initialize(container_klass:, opts:, klass_suffix:, method_name: :call!)
        @container_klass = container_klass
        @opts = opts
        @method_name = method_name
        @klass_suffix = klass_suffix
      end

      concerning :JobClass do
        def job_klass
          @job_klass ||= define_job_klass
        end

        private

        def define_job_klass
          return if Interactify.sidekiq_missing?

          this = self

          invalid_keys = this.opts.symbolize_keys.keys - VALID_KEYS

          raise ArgumentError, "Invalid keys: #{invalid_keys}" if invalid_keys.any?

          build_job_klass(opts).tap do |klass|
            klass.const_set(:JOBABLE_OPTS, opts)
            klass.const_set(:JOBABLE_METHOD_NAME, method_name)
          end
        end

        def build_job_klass(opts)
          Class.new do
            include Sidekiq::Job

            sidekiq_options(opts)

            def perform(...)
              self.class.module_parent.send(
                self.class::JOBABLE_METHOD_NAME, ...
              )
            end
          end
        end
      end

      def async_job_klass
        JobKlass.new(container_klass:, klass_suffix:).async_job_klass
      end
    end
  end
end

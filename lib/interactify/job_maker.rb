require 'sidekiq'
require 'sidekiq/job'

module Interactify
  class JobMaker
    attr_reader :opts, :method_name, :container_klass, :klass_suffix

    def initialize(container_klass:, opts:, klass_suffix:, method_name: :call!)
      @container_klass = container_klass
      @opts = opts
      @method_name = method_name
      @klass_suffix = klass_suffix
    end

    concerning :JobClass do
      def job_class
        @job_class ||= define_job_class
      end

      private

      def define_job_class
        this = self

        invalid_keys = this.opts.symbolize_keys.keys - %i[queue retry dead backtrace pool tags]

        raise ArgumentError, "Invalid keys: #{invalid_keys}" if invalid_keys.any?

        job_class = Class.new do
          include Sidekiq::Job

          sidekiq_options(this.opts)

          def perform(...)
            self.class.module_parent.send(self.class::JOBABLE_METHOD_NAME, ...)
          end
        end

        job_class.const_set(:JOBABLE_OPTS, opts)
        job_class.const_set(:JOBABLE_METHOD_NAME, method_name)
        job_class
      end
    end

    concerning :AsyncJobClass do
      def async_job_class
        klass = Class.new do
          include Interactor
          include Interactor::Contracts
        end

        attach_call(klass)
        attach_call!(klass)

        klass
      end

      def args(context)
        args = context.to_h.stringify_keys

        return args unless container_klass.respond_to?(:contract)

        restrict_to_optional_or_keys_from_contract(args)
      end

      private

      def attach_call(async_job_class)
        # e.g. SomeInteractor::AsyncWithSuffix.call(foo: 'bar')
        async_job_class.send(:define_singleton_method, :call) do |context|
          call!(context)
        end
      end

      def attach_call!(async_job_class)
        this = self

        # e.g. SomeInteractor::AsyncWithSuffix.call!(foo: 'bar')
        async_job_class.send(:define_singleton_method, :call!) do |context|
          # e.g. SomeInteractor::JobWithSuffix
          job_klass = this.container_klass.const_get("Job#{this.klass_suffix}")

          # e.g. SomeInteractor::JobWithSuffix.perform_async({foo: 'bar'})
          job_klass.perform_async(this.args(context))
        end
      end

      def restrict_to_optional_or_keys_from_contract(args)
        keys = container_klass
               .contract
               .expectations
               .instance_eval { @terms }
               .schema
               .key_map
               .to_dot_notation
               .map(&:to_s)

        optional = Array(container_klass.optional_attrs).map(&:to_s)
        keys += optional

        args.slice(*keys)
      end
    end
  end
end

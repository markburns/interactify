# frozen_string_literal: true

module Interactify
  module Async
    class JobKlass
      attr_reader :container_klass, :klass_suffix

      def initialize(container_klass:, klass_suffix:)
        @container_klass = container_klass
        @klass_suffix = klass_suffix
      end

      def async_job_klass
        klass = Class.new do
          include Interactor
          include Interactor::Contracts
        end

        attach_call(klass)
        attach_call!(klass)

        klass
      end

      def attach_call(async_job_klass)
        # e.g. SomeInteractor::AsyncWithSuffix.call(foo: 'bar')
        async_job_klass.send(:define_singleton_method, :call) do |context|
          call!(context)
        end
      end

      def attach_call!(async_job_klass)
        this = self

        # e.g. SomeInteractor::AsyncWithSuffix.call!(foo: 'bar')
        async_job_klass.send(:define_singleton_method, :call!) do |context|
          # e.g. SomeInteractor::JobWithSuffix
          job_klass = this.container_klass.const_get("Job#{this.klass_suffix}")

          # e.g. SomeInteractor::JobWithSuffix.perform_async({foo: 'bar'})
          job_klass.perform_async(this.args(context))
        end
      end

      def args(context)
        args = context.to_h.stringify_keys

        return args unless container_klass.respond_to?(:expected_keys)

        restrict_to_optional_or_keys_from_contract(args)
      end

      def restrict_to_optional_or_keys_from_contract(args)
        keys = Array(container_klass.expected_keys).map(&:to_s)

        optional = Array(container_klass.optional_attrs).map(&:to_s)
        keys += optional

        args.slice(*keys)
      end
    end
  end
end

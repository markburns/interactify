# frozen_string_literal: true

require "interactify/dsl/unique_klass_name"

module Interactify
  module Dsl
    class IfInteractor
      attr_reader :condition, :evaluating_receiver

      def self.attach_klass(evaluating_receiver, condition, succcess_interactor, failure_interactor)
        ifable = new(evaluating_receiver, condition, succcess_interactor, failure_interactor)
        ifable.attach_klass
      end

      def initialize(evaluating_receiver, condition, succcess_arg, failure_arg)
        @evaluating_receiver = evaluating_receiver
        @condition = condition
        @success_arg = succcess_arg
        @failure_arg = failure_arg
      end

      def success_interactor
        @success_interactor ||= build_chain(@success_arg, true)
      end

      def failure_interactor
        @failure_interactor ||= build_chain(@failure_arg, false)
      end

      # allows us to dynamically create an interactor chain
      # that iterates over the packages and
      # uses the passed in each_loop_klasses
      # rubocop:disable all
      def klass
        this = self

        klass_basis.tap do |k|
          k.instance_eval do
            expects do
              required(this.condition) unless this.condition.is_a?(Proc)
            end

            define_singleton_method(:source_location) do
              const_source_location this.evaluating_receiver.to_s                                     #     [file, line]
            end

            define_method(:run!) do
              result = this.condition.is_a?(Proc) ? this.condition.call(context) : context.send(this.condition)
              interactor = result ? this.success_interactor : this.failure_interactor
              interactor&.respond_to?(:call!) ? interactor.call!(context) : interactor&.call(context)
            end

            define_method(:inspect) do
              "<#{this.namespace}::#{this.if_klass_name} #{this.condition} ? #{this.success_interactor} : #{this.failure_interactor}>"
            end
          end
        end
      end
      # rubocop:enable all

      # so we have something to attach subclasses to during building
      # of the outer class, before we finalize the outer If class
      def klass_basis
        @klass_basis ||= Class.new do
          include Interactify
        end
      end

      def attach_klass
        name = if_klass_name
        namespace.const_set(name, klass)
        namespace.const_get(name)
      end

      def namespace
        evaluating_receiver
      end

      def if_klass_name
        @if_klass_name ||=
          begin
            prefix = condition.is_a?(Proc) ? "Proc" : condition
            prefix = "If#{prefix.to_s.camelize}"

            UniqueKlassName.for(namespace, prefix)
          end
      end

      private

      def build_chain(arg, truthiness)
        return if arg.nil?

        case arg
        when Array
          name = "If#{condition.to_s.camelize}#{truthiness ? "IsTruthy" : "IsFalsey"}"
          klass_basis.chain(name, *arg)
        else
          arg
        end
      end
    end
  end
end

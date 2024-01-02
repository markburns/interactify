# frozen_string_literal: true

require "interactify/dsl/unique_klass_name"
require "interactify/dsl/if_klass"

module Interactify
  module Dsl
    class IfInteractor
      attr_reader :condition, :evaluating_receiver, :caller_info

      def self.attach_klass(evaluating_receiver, condition, succcess_interactor, failure_interactor, caller_info:)
        ifable = new(evaluating_receiver, condition, succcess_interactor, failure_interactor, caller_info:)
        ifable.attach_klass
      end

      def initialize(evaluating_receiver, condition, succcess_arg, failure_arg, caller_info:)
        @evaluating_receiver = evaluating_receiver
        @condition = condition
        @success_arg = succcess_arg
        @failure_arg = failure_arg
        @caller_info = caller_info
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
      def klass
        IfKlass.new(self).klass
      end

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
          name = "If#{condition.to_s.camelize}#{truthiness ? 'IsTruthy' : 'IsFalsey'}"
          klass_basis.chain(name, *arg, caller_info:)
        else
          arg
        end
      end
    end
  end
end

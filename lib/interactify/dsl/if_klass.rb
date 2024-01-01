# frozen_string_literal: true

module Interactify
  module Dsl
    class IfKlass
      attr_reader :if_builder

      def initialize(if_builder)
        @if_builder = if_builder
      end

      def klass
        attach_expectations
        attach_source_location
        attach_run!
        attach_inspect

        if_builder.klass_basis
      end

      def run!(context)
        result = invoke_callable(context)

        interactor = result ? success_interactor : failure_interactor
        interactor.respond_to?(:call!) ? interactor.call!(context) : interactor&.call(context)
      end

      private

      def invoke_callable(context)
        return handle_string_or_symbol(context) if string_or_symbol_condition?
        return handle_interactor_subclass(context) if interactor_subclass_condition?
        return handle_proc_or_class(context) if proc_or_class_condition?

        raise_unknown_condition_error
      end

      def string_or_symbol_condition?
        condition.class.in?([String, Symbol])
      end

      def handle_string_or_symbol(context)
        context.send(condition)
      end

      def interactor_subclass_condition?
        condition.is_a?(Class) && condition < Interactor
      end

      def handle_interactor_subclass(context)
        condition.new(context).call
      end

      def proc_or_class_condition?
        condition.is_a?(Proc) || condition.is_a?(Class)
      end

      def handle_proc_or_class(context)
        condition.call(context)
      end

      def raise_unknown_condition_error
        raise "Unknown condition: #{condition.inspect}"
      end

      def attach_source_location
        attach do |_klass, this|
          define_singleton_method(:source_location) do            #   def self.source_location
            const_source_location this.evaluating_receiver.to_s   #     [file, line]
          end
        end
      end

      def attach_expectations
        attach do |klass, this|
          klass.expects do
            required(this.condition) if this.condition.class.in?([String, Symbol])
          end
        end
      end

      def attach_run!
        this = self

        attach_method(:run!) do
          this.run!(context)
        end
      end

      delegate :condition, :success_interactor, :failure_interactor, to: :if_builder

      def attach_inspect
        this = if_builder

        attach_method(:inspect) do
          name = "#{this.namespace}::#{this.if_klass_name}"
          "<#{name} #{this.condition} ? #{this.success_interactor} : #{this.failure_interactor}>"
        end
      end

      # rubocop: disable Naming/BlockForwarding
      def attach_method(name, &block)
        attach do |klass, _this|
          klass.define_method(name, &block)
        end
      end
      # rubocop: enable Naming/BlockForwarding

      def attach
        this = if_builder

        this.klass_basis.instance_eval do
          yield self, this
        end
      end
    end
  end
end

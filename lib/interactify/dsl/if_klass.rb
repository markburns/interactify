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
        result = condition.is_a?(Proc) ? condition.call(context) : context.send(condition)

        interactor = result ? success_interactor : failure_interactor
        interactor.respond_to?(:call!) ? interactor.call!(context) : interactor&.call(context)
      end

      private

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
            required(this.condition) unless this.condition.is_a?(Proc)
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

      def attach_method(name, &block)
        attach do |klass, _this|
          klass.define_method(name, &block)
        end
      end

      def attach
        this = if_builder

        this.klass_basis.instance_eval do
          yield self, this
        end
      end
    end
  end
end

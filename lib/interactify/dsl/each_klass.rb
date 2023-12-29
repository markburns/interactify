# frozen_string_literal: true

require "interactify/dsl/unique_klass_name"

module Interactify
  module Dsl
    class EachKlass
      attr_reader :builder

      def initialize(builder)
        @builder = builder
      end
      # allows us to dynamically create an interactor chain
      # that iterates over the packages and
      # uses the passed in each_loop_klasses
      # rubocop:disable all
      def klass
        this = self

        klass_basis.tap do |klass|
          this.attach_method(klass, :run!) do
            this.run!(context)
          end
        end
      end

      def run!(context)
        context.send(builder.plural_resource_name).each_with_index do |resource, index|#    context.packages.each_with_index do |package, index|
          process_resource(context, resource, index)                                #      process_resource(package, index)
        end                                                                         #    end

        reset_context(context)                                                      #    reset_context(context)

        context                                                                     #    context
      end

      def attach_method(klass, method_name, &block)
        klass.define_method(method_name, &block)
      end

      def attach_inspect
        define_method(:inspect) do
          "<#{builder.namespace}::#{builder.iterator_klass_name} iterates_over: #{builder.each_loop_klasses.inspect}>"
        end
      end

      private

      def process_resource(context, resource, index)
        setup_context(context, resource, index)                       #   setup_context(context, package, index)
        klasses = Wrapper.wrap_many(self, builder.each_loop_klasses)

        klasses.each do |interactor|                                  #   [WrappedLambdaA, B, C].each do |interactor|
          interactor.call!(context)                                   #     interactor.call!(context)
        end                                                           #   end
      end

      def setup_context(context, resource, index)                     #   def setup_context(context, package, index)
        context[builder.singular_resource_name] = resource               #       context.package = package
        context[builder.singular_resource_index_name] = index            #       context.package_index = index
      end

      def reset_context(context)                                      #    reset_context(context)
        context[builder.singular_resource_name] = nil                    #    context.package = nil
        context[builder.singular_resource_index_name] = nil              #    context.package_index = nil
      end

      def klass_basis
        this = builder

        Class.new do                                                  # class SomeNamespace::EachPackage
          include Interactify                                         #   include Interactify

          expects do                                                  #   expects do
            required(this.plural_resource_name)                       #     required(:packages)
          end                                                         #   end

          define_singleton_method(:source_location) do                #   def self.source_location
            const_source_location this.evaluating_receiver.to_s                   #     [file, line]
          end                                                         #   end
        end
      end
    end
  end
end

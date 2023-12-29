# frozen_string_literal: true

require "interactify/dsl/unique_klass_name"
require "interactify/dsl/each_klass"

module Interactify
  module Dsl
    class EachChain
      attr_reader :each_loop_klasses, :plural_resource_name, :evaluating_receiver

      def self.attach_klass(evaluating_receiver, plural_resource_name, *each_loop_klasses)
        iteratable = new(each_loop_klasses, plural_resource_name, evaluating_receiver)
        iteratable.attach_klass
      end

      def initialize(each_loop_klasses, plural_resource_name, evaluating_receiver)
        @each_loop_klasses = each_loop_klasses
        @plural_resource_name = plural_resource_name
        @evaluating_receiver = evaluating_receiver
      end

      # allows us to dynamically create an interactor chain
      # that iterates over the packages and
      # uses the passed in each_loop_klasses
      def klass
        EachKlass.new(self).klass
      end

      def attach_klass
        name = iterator_klass_name

        namespace.const_set(name, klass)
        namespace.const_get(name)
      end

      def namespace
        evaluating_receiver
      end

      def iterator_klass_name
        prefix = "Each#{singular_resource_name.to_s.camelize}"

        UniqueKlassName.for(namespace, prefix)
      end

      def singular_resource_name
        plural_resource_name.to_s.singularize.to_sym
      end

      def singular_resource_index_name
        "#{singular_resource_name}_index".to_sym
      end
    end
  end
end

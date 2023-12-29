# frozen_string_literal: true

module Interactify
  module Dsl
    module UniqueKlassName
      def self.for(namespace, prefix)
        id = generate_unique_id
        klass_name = :"#{prefix}#{id}"

        while namespace.const_defined?(klass_name)
          id = generate_unique_id
          klass_name = :"#{prefix}#{id}"
        end

        klass_name.to_sym
      end

      def self.generate_unique_id
        rand(10_000)
      end
    end
  end
end

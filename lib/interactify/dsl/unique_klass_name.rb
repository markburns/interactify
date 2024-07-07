# frozen_string_literal: true

module Interactify
  module Dsl
    module UniqueKlassName
      module_function

      def for(namespace, prefix, camelize: true)
        prefix = "AnonymousModule" if prefix.is_a?(Module) && prefix.anonymous?

        prefix = normalize_prefix(prefix:, camelize:)
        klass_name = name_with_suffix(namespace, prefix, nil)

        loop do
          return klass_name.to_sym if klass_name

          klass_name = name_with_suffix(namespace, prefix, generate_unique_id)
        end
      end

      def name_with_suffix(namespace, prefix, suffix)
        name = [prefix.to_s, suffix.to_s].reject(&:blank?).join("_")

        return nil if namespace.const_defined?(name.to_sym)

        name
      end

      def normalize_prefix(prefix:, camelize:)
        normalized = prefix.to_s.gsub(/::/, "__")
        return normalized unless camelize

        normalized.camelize
      end

      def generate_unique_id
        rand(10_000)
      end
    end
  end
end

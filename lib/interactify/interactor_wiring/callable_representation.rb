require 'interactify/interactor_wiring/error_context'

module Interactify
  class InteractorWiring
    class CallableRepresentation
      attr_reader :filename, :klass, :wiring

      delegate :interactor_lookup, to: :wiring

      def initialize(filename:, klass:, wiring:)
        @filename = filename
        @klass = klass
        @wiring = wiring
      end

      def validate_callable(error_context: ErrorContext.new)
        if organizer?
          assign_previously_defined(error_context:)
          validate_children(error_context:)
        end

        validate_self(error_context:)
      end

      def expected_keys
        klass.respond_to?(:expected_keys) ? Array(klass.expected_keys) : []
      end

      def promised_keys
        klass.respond_to?(:promised_keys) ? Array(klass.promised_keys) : []
      end

      def all_keys
        expected_keys.concat(promised_keys)
      end

      def inspect
        "#<#{self.class.name}#{object_id} @filename=#{filename}, @klass=#{klass.name}>"
      end

      def organizer?
        klass.respond_to?(:organized) && klass.organized.any?
      end

      def assign_previously_defined(error_context:)
        return unless contract?

        error_context.append_previously_defined_keys(all_keys)
      end

      def validate_children(error_context:)
        klass.organized.each do |interactor|
          interactor_as_callable = interactor_lookup[interactor]
          next if interactor_as_callable.nil?

          error_context = interactor_as_callable.validate_callable(error_context:)
        end

        error_context
      end

      private

      def contract?
        klass.ancestors.include? Interactor::Contracts
      end

      def validate_self(error_context:)
        return error_context unless contract?

        error_context.infer_missing_keys(self)
        error_context.add_promised_keys(promised_keys)
        error_context
      end
    end
  end
end

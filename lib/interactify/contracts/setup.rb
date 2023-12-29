# frozen_string_literal: true

module Interactify
  module Contracts
    class Setup
      def self.expects(context:, attrs:, filled:)
        new(context:, attrs:, filled:).setup(:expects)
      end

      def self.promises(context:, attrs:, filled:, should_delegate:)
        new(context:, attrs:, filled:, should_delegate:).setup(:promises)
      end

      def initialize(context:, attrs:, filled:, should_delegate: true)
        @context = context
        @attrs = attrs
        @filled = filled
        @should_delegate = should_delegate
      end

      def setup(meth)
        this = self

        @context.send(meth) do
          this.setup_attrs self
        end

        @context.delegate(*@attrs, to: :context) if @should_delegate
      end

      def setup_attrs(contract)
        @attrs.each do |attr|
          field = contract.required(attr)
          field.filled if @filled
        end
      end
    end
  end
end

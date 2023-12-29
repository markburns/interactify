# frozen_string_literal: true

module Interactify
  module Async
    class NullJob
      def method_missing(...)
        self
      end

      def self.method_missing(...)
        self
      end

      def respond_to_missing?(...)
        true
      end

      def self.respond_to_missing?(...)
        true
      end
    end
  end
end

# frozen_string_literal: true

require "interactify/contracts/failure"

module Interactify
  module Contracts
    class MismatchingOrganizerError < Contracts::Failure
      def initialize(interactor, organizing, organized_klasses)
        @interactor = interactor
        @organizing = organizing
        @organized_klasses = organized_klasses

        super(formatted_message)
      end

      private

      attr_reader :interactor, :organizing, :organized_klasses

      def formatted_message
        <<~MESSAGE.chomp.strip
          #{interactor} does not organize:
          #{organizing.inspect}

          Actual organized classes are:
          #{organized_klasses.inspect}

          #{missing_and_extra_message}
        MESSAGE
      end

      def extra = organizing - organized_klasses
      def missing = organized_klasses - organizing
      def missing_message = missing.none? ? nil : "Missing classes are:\n#{missing.inspect}"
      def extra_message = extra.none? ? nil : "Extra classes are:\n#{extra.inspect}"

      def missing_and_extra_message = [missing_message, extra_message].compact.join("\n\n")
    end
  end
end

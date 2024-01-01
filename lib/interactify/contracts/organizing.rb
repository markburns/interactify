# frozen_string_literal: true

require "interactify/contracts/mismatching_organizer_error"

module Interactify
  module Contracts
    class Organizing
      attr_reader :interactor, :organizing

      def self.validate(interactor, *organizing)
        new(interactor, *organizing).validate

        interactor
      end

      def initialize(interactor, *organizing)
        @interactor = interactor
        @organizing = organizing
      end

      def validate
        return if organizing == organized

        raise MismatchingOrganizerError.new(interactor, organizing, organized)
      end

      delegate :organized, to: :interactor
    end
  end
end

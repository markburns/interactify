# frozen_string_literal: true

require "interactify/mismatching_promise_error"

module Interactify
  class Promising
    attr_reader :interactor, :promising

    def self.validate(interactor, *promising)
      new(interactor, *promising).validate

      interactor
    end

    def initialize(interactor, *promising)
      @interactor = interactor
      @promising = format_keys promising
    end

    def validate
      return if promising == promised_keys

      raise MismatchingPromiseError.new(interactor, promising, promised_keys)
    end

    def promised_keys
      format_keys interactor.promised_keys
    end

    def format_keys(keys)
      Array(keys).compact.map(&:to_sym).sort
    end
  end
end

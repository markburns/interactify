require 'interactify/mismatching_promise_error'

module Interactify
  class Promising
    attr_reader :interactor, :args

    def self.validate(interactor, *args)
      new(interactor, *args).validate

      interactor
    end

    def initialize(interactor, *args)
      @interactor = interactor
      @args = args
    end

    def validate
      return if args.sort == interactor.promised_keys

      raise MismatchingPromiseError.new(interactor, args)
    end
  end
end

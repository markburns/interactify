# frozen_string_literal: true

require "interactify/contract_failure"

module Interactify
  class MismatchingPromiseError < ContractFailure
    def initialize(interactor, promising, promised_keys)
      super <<~MESSAGE.chomp
        #{interactor} does not promise:
        #{promising.inspect}

        Actual promises are:
        #{promised_keys.inspect}
      MESSAGE
    end
  end
end

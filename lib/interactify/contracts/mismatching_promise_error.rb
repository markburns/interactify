# frozen_string_literal: true

require "interactify/contracts/failure"

module Interactify
  module Contracts
    class MismatchingPromiseError < Contracts::Failure
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
end

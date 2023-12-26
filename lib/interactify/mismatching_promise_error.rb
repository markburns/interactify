require 'interactify/contract_failure'

module Interactify
  class MismatchingPromiseError < ContractFailure
    def initialize(interactor, promising)
      super <<~MESSAGE.chomp
        #{interactor} does not promise:
        #{promising}

        Actual promises are:
        #{interactor.promised_keys}
      MESSAGE
    end
  end
end

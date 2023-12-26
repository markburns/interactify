require 'interactify/contract_failure'

module Interactify
  class MismatchingPromiseError < ContractFailure
    def initialize(interactor, promising)
      super <<~MESSAGE.chomp
        #{interactor} does not promise:
        #{promising.map(&:inspect).join(', ')}

        Actual promises are:
        #{interactor.promised_keys.map(&:inspect).join(', ')}
      MESSAGE
    end
  end
end

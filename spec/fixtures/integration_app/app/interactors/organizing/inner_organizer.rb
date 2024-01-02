require_relative 'organized1'
require_relative 'organized2'
require_relative 'deeply_nested_interactor'
require_relative 'deeply_nested_promising_interactor'

module Organizing
  class InnerOrganizer
    include Interactify

    organize \
      Organized1, 
      Organized2.organizing(
        DeeplyNestedInteractor,
        DeeplyNestedPromisingInteractor.promising(
          :deeply_nested_promising_interactor_called
        ),
        Organized2::Organized2Called
      )
  end
end

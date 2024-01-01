require_relative 'deeply_nested_interactor'
require_relative 'deeply_nested_promising_interactor'

module Organizing
  class Organized2
    include Interactify

    organize(
        DeeplyNestedInteractor,
        DeeplyNestedPromisingInteractor.promising(
          :deeply_nested_promising_interactor_called
        ),
        Organized2Called = Interactify do |context|
          context.organized2_called = true
        end
      )
  end
end

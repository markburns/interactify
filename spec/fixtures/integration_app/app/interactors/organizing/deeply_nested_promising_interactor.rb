module Organizing
  class DeeplyNestedPromisingInteractor
    include Interactify

    promise :deeply_nested_promising_interactor_called

    def call
      context.deeply_nested_promising_interactor_called = true
    end
  end
end

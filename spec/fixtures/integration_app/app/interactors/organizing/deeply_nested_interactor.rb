module Organizing
  class DeeplyNestedInteractor
    include Interactify

    def call
      context.deeply_nested_interactor_called = true
    end
  end
end

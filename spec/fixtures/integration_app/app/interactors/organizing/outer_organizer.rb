require_relative 'inner_organizer'

module Organizing
  class OuterOrganizer
    include Interactify

    organize \
      InnerOrganizer.organizing(
        Organized1, 
        Organized2.organizing(
          DeeplyNestedInteractor,
          DeeplyNestedPromisingInteractor.promising(
            :deeply_nested_promising_interactor_called
          ),
          Organized2::Organized2Called
        )
      )
  end
end

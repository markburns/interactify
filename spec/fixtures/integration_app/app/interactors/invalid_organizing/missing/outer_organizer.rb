require_relative '../../organizing/inner_organizer'

module InvalidOrganizing
  module Missing
    class OuterOrganizer
      include Interactify

      organize \
        Organizing::InnerOrganizer.organizing(
          Organizing::Organized1, 
          Organizing::Organized2.organizing(
            Organizing::DeeplyNestedInteractor,
            Organizing::DeeplyNestedPromisingInteractor.promising(
              :deeply_nested_promising_interactor_called
            )
          )
        )
    end
  end
end

require_relative '../../organizing/inner_organizer'

module InvalidOrganizing
  module Extra
    class OuterOrganizer
      include Interactify

      Unexpected = Interactify do |context|
        context.unexpected = true
      end

      organize \
        Organizing::InnerOrganizer.organizing(
          Unexpected,
          Organizing::Organized1, 
          Organizing::Organized2.organizing(
            Organizing::DeeplyNestedInteractor,
            Organizing::DeeplyNestedPromisingInteractor.promising(
              :deeply_nested_promising_interactor_called
            ),
            Organizing::Organized2::Organized2Called,
          )
        )
    end
  end
end

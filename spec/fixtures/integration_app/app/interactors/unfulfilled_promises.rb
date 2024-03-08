require_relative "./organizing/organized1"
require_relative "./organizing/organized2"

class UnfulfilledPromises
  include Interactify

  expect :dont_fulfill, filled: false
  expect :things
  promise :something_unfulfilled
  promise :another_thing

  organize each(
    :things,
    {
      if: :dont_fulfill,
      then: chain(
        :nested_promises,
        each(
          :things,
          Organizing::Organized1.promising(
            :organized1_called
          ),
          SetAnothingThing = Interactify { _1.another_thing = true },
          Organizing::Organized2.organizing(
            Organizing::DeeplyNestedInteractor,
            Organizing::DeeplyNestedPromisingInteractor.promising(
              :deeply_nested_promising_interactor_called
            ),
            Organizing::Organized2::Organized2Called
          )
        )
      ),
      else: DoSomethingElse = Interactify { _1.something_unfulfilled = true }
    }
  )
end

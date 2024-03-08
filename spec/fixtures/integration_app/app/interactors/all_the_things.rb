# This is test code.
#
# Avoid using organizers predominantly composed of lambdas. In complex organizers,
# it's common to have many isolated interactor classes, but maintain some orchestration
# code for readability and cohesion.
#
# For instance, rather than creating an EachProduct interactor or a separate interactor chain
# for a single boolean flag, it's more efficient to manage the high-level business process
# in one location. This approach reduces the need to switch between two mindsets:
#
# Mode 1 (High-Level Overview): Understanding the business process and identifying where changes fit.
# Mode 2 (Detailed Implementation): Focusing on the specific logic of a process step.
#
# Initially, in Mode 1, a bird's-eye view is essential for grasping the process architecture.
# Once this overview is clear, you pinpoint the relevant interactor for modifications or additions,
# transitioning to Mode 2 for implementation.
#
# This distinction between modes is crucial. Mode 1 involves more reading, conceptualizing,
# and questioning, often requiring navigation through multiple files and note-taking.
# Mode 2 is about active coding and editing. Minimizing context switching between these modes
# saves time and mental energy. It's also easier to maintain a high-level overview of the process
# when the code is in one place.
#
# Typically this will allow us to move closer towards a one organizer per interaction model.
# E.g. one Rails action == one organizer.
# Even the background job firing can be handled by the organizer via YourClass::Async.
#
# An improvement we aim for is automatic diagram generation from the organizers, utilizing
# contracts for documentation.
#
# Note: The conditional structures (`if`, `each`) here are not executed at runtime in the usual
# sense. They are evaluated when defining the organizer, leading to the creation of discrete
# classes that handle the respective logic.

require_relative "./organizing/organized1"
require_relative "./organizing/organized2"
require_relative "./if/a"
require_relative "./if/b"
require_relative "./if/c"
require_relative "./if/d"
require_relative "./if/organizer"

class AllTheThings
  include Interactify

  expect :things
  optional :optional_thing
  promise :a

  organize \
    self.if(
      :things,
      then: [If::A, If::B],
      else: [If::C, If::D]
    ),
    # test nested promises
    chain(
      :nested_promises,
      Organizing::Organized1.promising(
        :organized1_called
      ),
      Organizing::Organized2.organizing(
        Organizing::DeeplyNestedInteractor,
        Organizing::DeeplyNestedPromisingInteractor.promising(
          :deeply_nested_promising_interactor_called
        ),
        Organizing::Organized2::Organized2Called
      )
    ),
    # test each with lambda
    self.if(
      ->(c) { c.things },
      each(
        :things,
        If::A,
        If::B,
        ->(c) { c.lambda_set = true }
      )
    ),
    # test alternative if syntax
    self.if(
      ->(c) { c.a && c.b },
      then: ->(c) { c.both_a_and_b = true },
      else: ->(c) { c.both_a_and_b = false }
    ),
    # test setting a value to use later in the chain
    ->(c) { c.more_things = [1, 2, 3, 4] },
    # test lambdas inside each
    each(
      :more_things,
      lambda { |c|
        c.first_more_thing = true if c.more_thing_index.zero?
      },
      lambda { |c|
        c.next_more_thing = true if c.more_thing_index == 1
      },
      # test nested if inside each
      { if: :not_set_thing, then: ->(c) { c.not_set_thing = true } },
      # test setting a value after an else
      ->(c) { c.more_thing = true }
    ),
    self.if(
      :optional_thing,
      then: [
        ->(c) { c.optional_thing_was_set = true },
        ->(c) { c.and_then_another_thing = true },
        ->(c) { c.and_one_more_thing = true },
        # test nested each inside if
        each(:more_things,
             ->(c) { c.more_things[c.more_thing_index] = c.more_thing + 5 },
             ->(c) { c.more_things[c.more_thing_index] = c.more_thing + 5 })
      ],
      else: ->(c) { c.optional_thing_was_set = false }
    ),
    # if -> each -> if -> each
    self.if(:condition, then: [-> {}], else: [
              each(
                :things,
                self.if(
                  :thing,
                  then: each(
                    :more_things,
                    lambda { |c|
                      c.counter ||= 0
                      c.counter += 1
                    }
                  )
                )
              )
            ]),
    # each -> each -> each
    each(
      :more_things,
      each(
        :more_things,
        each(
          :more_things,
          each(
            :more_things,
            lambda { |c|
              c.heavily_nested_counter ||= 0
              c.heavily_nested_counter += 1
            }
          )
        )
      )
    )
end

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

    self.each(
      :things, 
      If::A, 
      If::B, 
      -> (c) { c.lambda_set = true }
    ),

    self.if(
      -> (c) { c.a && c.b } ,
      then: -> (c) { c.both_a_and_b = true },
      else: -> (c) { c.both_a_and_b = false}
    ),

    -> (c) { c.more_things = [1, 2, 3, 4] },

    self.each(
      :more_things, 
      -> (c) {
        if c.more_thing_index.zero? 
          c.first_more_thing = true
        end
      },
      -> (c) { 
        if c.more_thing_index == 1
          c.next_more_thing = true 
        end
      },
      {if: :not_set_thing, then: -> (c) { c.not_set_thing = true } },
      -> (c) { c.more_thing = true }
    ),

    self.if(
      :optional_thing, 
      then: [
        -> (c) { c.optional_thing_was_set = true },
        -> (c) { c.and_then_another_thing = true },
        -> (c) { c.and_one_more_thing = true },
        self.each(:more_things, 
                  -> (c) { c.more_things[c.more_thing_index] = c.more_thing + 5 },
                  -> (c) { c.more_things[c.more_thing_index] = c.more_thing + 5 }
         )
      ],
      else: -> (c) { c.optional_thing_was_set = false }
    )
end

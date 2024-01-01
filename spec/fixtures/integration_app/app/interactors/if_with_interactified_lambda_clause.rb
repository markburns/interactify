module A
  module B
    class IfWithInteractifiedLambdaClause
      include Interactify
      expect :some_flag_is_set, filled: false

      SomeFlagIsSet = Interactify(&:some_flag_is_set)
      SomeFlagIsSet = Interactify do |c|
        c.some_flag_is_set
      end

      organize self.if(
        SomeFlagIsSet,
        then: -> { _1.was_set = true },
        else: -> { _1.was_set = false }
      )
    end
  end
end

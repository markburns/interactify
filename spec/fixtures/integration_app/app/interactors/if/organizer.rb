module If
  module Organizer
    class Anyways
      include Interactify

      expect :blah, filled: false

      def call
        context.anyways = blah
      end
    end

    class MethodSyntaxOrganizer
      include Interactify
      expect :blah, filled: false

      organize \
        self.if(:blah, [A, B], [C, D]),
        Anyways
    end

    class AlternativeMethodSyntaxOrganizer
      include Interactify
      expect :blah, filled: false

      organize(
        self.if(:blah, then: [A, B], else: [C, D]),
        Anyways
      )
    end

    class HashSyntaxOrganizer
      include Interactify
      expect :blah, filled: false

      organize(
        { if: :blah, then: [A, B], else: [C, D] },
        Anyways
      )
    end
  end
end

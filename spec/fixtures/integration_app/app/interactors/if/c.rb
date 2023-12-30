module If
  class C
    include Interactify

    def call
      context.c = 'c'
      return unless context.thing

      context.thing.c = 'c'
      context.thing.c_index = context.thing_index
    end
  end
end

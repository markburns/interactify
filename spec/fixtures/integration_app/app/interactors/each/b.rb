module Each
  class B
    include Interactify

    def call
      context.b = 'b'
      return unless context.thing

      context.thing.b = 'b'
      context.thing.b_index = context.thing_index
    end
  end
end

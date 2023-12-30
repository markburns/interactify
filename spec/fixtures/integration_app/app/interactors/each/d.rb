module Each
  class D
    include Interactify

    def call
      context.d = 'd'
      return unless context.thing

      context.thing.d = 'd'
      context.thing.d_index = context.thing_index
    end
  end
end

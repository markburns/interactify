module Each
  class A
    include Interactify

    def call
      context.a = 'a'
      return unless context.thing

      context.thing.a = 'a'
      context.thing.a_index = context.thing_index
    end
  end
end

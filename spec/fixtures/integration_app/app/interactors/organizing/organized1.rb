module Organizing
  class Organized1
    include Interactify

    promise :organized1_called

    def call
      context.organized1_called = true
    end
  end
end

require_relative 'one'
require_relative 'two'
require_relative 'three'

module SpecSupport
  module WithinNamespace
    class Organizer
      include Interactor::Organizer
      include Interactor::Contracts

      delegate :foo, :bar, :baz, to: :context

      organize \
        One,
        Two,
        Three
    end
  end
end

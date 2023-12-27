require_relative 'one'
require_relative 'two'
require_relative 'three'

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

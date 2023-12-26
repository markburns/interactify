module SpecSupport
  class DummyOrganizer
    include Interactor::Organizer
    include Interactor::Contracts

    expects do
      required(:foo)
      required(:bar)
      required(:baz)
    end

    delegate :foo, :bar, :baz, to: :context

    organize \
      DummyInteractor1,
      DummyInteractor2,
      DummyInteractor3,
      DummyInteractor4
  end
end

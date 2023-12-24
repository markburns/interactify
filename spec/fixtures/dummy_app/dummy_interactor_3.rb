module SpecSupport
  class DummyInteractor3
    include Interactor
    include Interactor::Contracts

    delegate :foo, :bar, :baz, to: :context
  end
end

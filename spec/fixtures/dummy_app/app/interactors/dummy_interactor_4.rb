module SpecSupport
  class DummyInteractor4
    include Interactor
    include Interactor::Contracts

    delegate :foo, :bar, :baz, to: :context
  end
end

class DummyInteractor2
  include Interactor
  include Interactor::Contracts

  delegate :foo, :bar, :baz, to: :context
end

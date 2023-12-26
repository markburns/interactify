class DummyInteractor1
  include Interactor

  delegate :foo, :bar, :baz, to: :context
end

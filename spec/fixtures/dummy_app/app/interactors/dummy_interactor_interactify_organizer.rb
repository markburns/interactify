class DummyInteractorInteractifyOrganizer
  include Interactify

  expect :a, :b, :c

  organize \
    DummyInteractor1,
    DummyInteractor2,
    DummyInteractor3,
    DummyInteractor4
end

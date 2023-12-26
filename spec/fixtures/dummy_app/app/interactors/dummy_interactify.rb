class DummyInteractify
  include Interactify

  expects do
    required(:foo)
    required(:bar)
    required(:baz)
  end

  def call
  end
end

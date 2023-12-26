module WithinNamespace
  class Three
    include Interactor
    include Interactor::Contracts

    expects do
      required(:baz)
    end

    delegate :foo, :bar, :baz, to: :context
  end
end

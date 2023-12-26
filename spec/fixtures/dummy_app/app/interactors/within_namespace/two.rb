module WithinNamespace
  class Two
    include Interactor
    include Interactor::Contracts

    expects do
      required(:phoo)
    end

    promises do
      required(:baz)
    end

    delegate :foo, :bar, :baz, to: :context
  end
end

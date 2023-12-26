module SpecSupport
  module WithinNamespace
    class One
      include Interactor
      include Interactor::Contracts

      expects do
        required(:foo)
      end

      promises do
        required(:bar)
      end

      delegate :foo, :bar, :baz, to: :context
    end
  end
end

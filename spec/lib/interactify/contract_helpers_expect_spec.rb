RSpec.describe Interactify do
  describe '.expect' do
    class DummyInteractorClass
      include Interactify
      expect :thing
      expect :this, filled: false

      promise :another

      def call
        context.another = thing
      end
    end

    class DummyOrganizerClass
      include Interactify
      expect :thing
      promise :another

      organize \
        DummyInteractorClass,
        DummyInteractorClass
    end

    it 'is simplified syntax for an expects block' do
      expect { DummyOrganizerClass.call! }.to raise_error DummyOrganizerClass::InteractorContractFailure
      result = DummyOrganizerClass.call!(thing: 'thing', this: nil)
      expect(result.another).to eq 'thing'
    end
  end
end

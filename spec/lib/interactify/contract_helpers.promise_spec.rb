# frozen_string_literal: true

RSpec.describe Interactify do
  describe ".promise" do
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

    it "is simplified syntax for a promises block" do
      expect { DummyOrganizerClass.call! }.to raise_error DummyOrganizerClass::InteractorContractFailure
      result = DummyOrganizerClass.call!(thing: "thing", this: nil)
      expect(result.another).to eq "thing"
      expect { DummyOrganizerClass.call!(thing: nil) }.to raise_error do |err|
        expect(err).to be_a DummyOrganizerClass::InteractorContractFailure
      end
    end
  end
end

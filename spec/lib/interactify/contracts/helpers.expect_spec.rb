# frozen_string_literal: true

RSpec.describe Interactify do
  self::DummyInteractorClass = Class.new do
    include Interactify
    expect :thing
    expect :this, filled: false

    promise :another

    def call
      context.another = thing
    end
  end

  this = self

  self::DummyOrganizerClass = Class.new do
    include Interactify
    expect :thing
    promise :another

    organize \
      this::DummyInteractorClass,
      this::DummyInteractorClass
  end

  describe ".expect" do
    it "is simplified syntax for an expects block" do
      expect { this::DummyOrganizerClass.call! }.to raise_error this::DummyOrganizerClass::InteractorContractFailure
      result = this::DummyOrganizerClass.call!(thing: "thing", this: nil)
      expect(result.another).to eq "thing"
    end
  end
end

# frozen_string_literal: true

RSpec.describe Interactify::Core do
  self::DummyClass = Class.new do
    include Interactify::Core
  end

  this = self

  describe "#called_klass_list" do
    let(:dummy_context) do
      ctx = Interactor::Context.new
      allow(ctx).to receive(:_called) { [1, 2.3, "some string"] }
      ctx
    end

    subject do
      this::DummyClass.new(dummy_context)
    end

    it "returns the list of called classes" do
      expect(subject.called_klass_list).to eq([Integer, Float, String])
    end
  end
end

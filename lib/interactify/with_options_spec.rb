# frozen_string_literal: true

RSpec.describe Interactify::WithOptions do
  let(:dummy_class) { Class.new }

  let(:sidekiq_opts) { { queue: "critical", retry: 5 } }
  let(:instance) { described_class.new(dummy_class, sidekiq_opts) }

  describe "#setup" do
    before do
      allow(dummy_class).to receive(:include).and_call_original
      allow(dummy_class).to receive(:const_set).and_call_original
    end

    it "includes core and async jobable modules in the receiver" do
      expect(dummy_class).to receive(:include).with(Interactify::Core)
      expect(dummy_class).to receive(:include).with(Interactify::Async::Jobable)
      instance.setup
    end

    it "defines job and async classes with correct suffixes based on options" do
      suffix = instance.klass_suffix
      expect(dummy_class).to receive(:const_set).with("Job#{suffix}", anything)
      expect(dummy_class).to receive(:const_set).with("Async#{suffix}", anything)
      instance.setup
    end

    context "when options include valid keys" do
      it "does not raise an error" do
        expect { instance.setup }.not_to raise_error
      end
    end

    context "when options include invalid keys" do
      let(:sidekiq_opts) { { invalid_key: "value" } }

      it "raises an ArgumentError" do
        expect { instance.setup }.to raise_error(ArgumentError, /Invalid keys: \[:invalid_key\]/)
      end
    end
  end
end

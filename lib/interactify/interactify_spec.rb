# frozen_string_literal: true

RSpec.describe Interactify do
  it "has a version number" do
    expect(Interactify::VERSION).not_to be nil
  end

  describe ".validate_app" do
    before do
      wiring = instance_double(Interactify::Wiring, validate_app: "ok")

      expect(Interactify::Wiring)
        .to receive(:new)
        .with(root: Interactify.configuration.root, ignore:)
        .and_return(wiring)
    end

    context "with an ignore" do
      let(:ignore) { %w[foo bar] }

      it "validates the app" do
        expect(Interactify.validate_app(ignore:)).to eq("ok")
      end
    end

    context "with nil ignore" do
      let(:ignore) { nil }

      it "validates the app" do
        expect(Interactify.validate_app(ignore:)).to eq("ok")
      end
    end

    context "with empty ignore" do
      let(:ignore) { [] }

      it "validates the app" do
        expect(Interactify.validate_app(ignore:)).to eq("ok")
      end
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(Interactify::Configuration)
    end
  end

  describe ".root" do
    before do
      Interactify.configure do |config|
        config.root = "foo"
      end
    end

    it "returns the root path" do
      expect(described_class.root).to eq("foo")
    end
  end
end

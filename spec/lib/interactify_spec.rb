# frozen_string_literal: true

RSpec.describe Interactify do
  it "has a version number" do
    expect(Interactify::VERSION).not_to be nil
  end

  describe '.trigger_definition_error' do
    context 'with the definition error handler set' do
      before do
        Interactify.on_definition_error do |error|
          "foo: #{error}"
        end
      end

      it 'triggers the handler' do
        expect(Interactify.trigger_definition_error('some_error')).to eq('foo: some_error')
      end
    end
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

  describe ".reset" do
    context "with a before raise hook" do
      before do
        described_class.before_raise { "foo" }
      end

      it "resets the hooks" do
        expect { described_class.reset }
          .to change { described_class.instance_eval { @before_raise_hook&.call } }
          .from("foo")
          .to(nil)
      end
    end

    context "with a contract breach hook" do
      before do
        described_class.on_contract_breach { "foo" }
      end

      it "resets the hooks" do
        expect { described_class.reset }
          .to change { described_class.instance_eval { @on_contract_breach&.call } }
          .from("foo")
          .to(nil)
      end
    end

    context "with configuration" do
      before do
        described_class.configure do |config|
          config.root = "foo"
        end
      end

      it "resets the configuration" do
        expect(described_class.configuration.root).to eq("foo")
        expect { described_class.reset }
          .to change { described_class.instance_eval { @configuration } }
          .from(instance_of(Interactify::Configuration))
          .to(nil)

        path = Interactify.railties? ? Pathname.new("spec/example_app/app") : nil
        expect(described_class.configuration.root).to eq(path)
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

  describe ".on_contract_breach" do
    it "sets the contract breach handler" do
      expect { Interactify.on_contract_breach { "foo" } }
        .to change { Interactify.trigger_contract_breach_hook { _1 } }
        .from(nil)
        .to("foo")
    end
  end
end

# frozen_string_literal: true

RSpec.describe Interactify::Hooks do
  describe ".trigger_definition_error" do
    context "with the definition error handler set" do
      before do
        Interactify.on_definition_error do |error|
          "foo: #{error}"
        end
      end

      it "triggers the handler" do
        expect(Interactify.trigger_definition_error("some_error")).to eq("foo: some_error")
      end
    end
  end

  describe ".reset" do
    context "with a before raise hook" do
      before do
        Interactify.before_raise { "foo" }
      end

      it "resets the hooks" do
        expect { Interactify.reset }
          .to change { Interactify.instance_eval { @before_raise_hook&.call } }
          .from("foo")
          .to(nil)
      end
    end

    context "with a contract breach hook" do
      before do
        Interactify.on_contract_breach { "foo" }
      end

      it "resets the hooks" do
        expect { Interactify.reset }
          .to change { Interactify.instance_eval { @on_contract_breach&.call } }
          .from("foo")
          .to(nil)
      end
    end

    context "with configuration" do
      before do
        Interactify.configure do |config|
          config.root = "foo"
        end
      end

      it "resets the configuration" do
        expect(Interactify.configuration.root).to eq("foo")
        expect { Interactify.reset }
          .to change { Interactify.instance_eval { @configuration } }
          .from(instance_of(Interactify::Configuration))
          .to(nil)

        path = Interactify.railties? ? Pathname.new("spec/example_app/app") : nil
        expect(Interactify.configuration.root).to eq(path)
      end
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

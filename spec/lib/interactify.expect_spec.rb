# frozen_string_literal: true

RSpec.describe Interactify do
  describe ".expect" do
    self::DummyInteractorClass = Class.new do
      include Interactify
      expect :thing
      expect :this, filled: false
      def call; end
    end

    noisy_context = {}

    10.times do
      s = SecureRandom.alphanumeric(50)
      s.gsub!(/^\d/, "")
      noisy_context[s] = SecureRandom.uuid
    end
    NOISY_CONTEXT = noisy_context

    this = self

    self::AnotherDummyInteractorOrganizerClass = Class.new do
      include Interactify

      organize this::DummyInteractorClass

      def call
        NOISY_CONTEXT.each do |k, v|
          context.send(:"#{k}=", v)
        end

        super
      end
    end

    context "when breaking the promise" do
      let(:failures) do
        {
          called_klass_list: "DummyInteractorClass",
          contract_failures:
        }
      end

      let(:contract_failures) do
        { thing: ["thing is missing"], this: ["this is missing"] }
      end

      context "when using call" do
        let(:result) { this::AnotherDummyInteractorOrganizerClass.call }

        it "does not raise" do
          expect { result }.not_to raise_error
          expect(result.contract_failures).to eq failures[:contract_failures]
        end
      end

      class self::Events
        def self.log_error(exception); end
      end

      before do
        Interactify.before_raise do |exception|
          @logged_exception = exception
        end

        Interactify.on_contract_breach do |ctx, contract_failures|
          @some_context = ctx.to_h.symbolize_keys
          @contract_failures = contract_failures.to_h.symbolize_keys
        end
      end

      it "raises a useful error", :aggregate_failures do
        expect { this::AnotherDummyInteractorOrganizerClass.call! }.to raise_error do |e|
          expect(e.class).to eq this::DummyInteractorClass::InteractorContractFailure

          outputted_failures = JSON.parse(e.message)

          expect(outputted_failures.symbolize_keys).to eq(failures[:contract_failures].symbolize_keys)
        end

        expect(@some_context).to eq NOISY_CONTEXT.symbolize_keys
        expect(@contract_failures).to eq contract_failures.symbolize_keys
        expect(@logged_exception).to be_a this::DummyInteractorClass::InteractorContractFailure
      end
    end
  end
end

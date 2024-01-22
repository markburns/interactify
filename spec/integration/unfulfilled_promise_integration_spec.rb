# frozen_string_literal: true

RSpec.describe "Unfulfilled promises" do
  let(:result) { klass.call(things:, dont_fulfill:, another_thing:) }
  let(:another_thing) { true }

  let(:klass) do
    UnfulfilledPromises.promising(:something_unfulfilled, :another_thing)
  end

  let(:things) do
    [thing1, thing2]
  end

  let(:thing1) do
    OpenStruct.new
  end

  let(:thing2) do
    OpenStruct.new
  end

  before do
    require "./spec/fixtures/integration_app/app/interactors/unfulfilled_promises"
  end

  context "when calling with call" do
    let(:result) { klass.call(things:, dont_fulfill:, another_thing:) }

    context "when not fulfilling" do
      let(:dont_fulfill) { true }

      it "does not raise" do
        expect { result }.not_to raise_error

        expect(result.contract_failures).to eq(
          { something_unfulfilled: ["something_unfulfilled is missing"] }
        )
      end
    end

    context "when fulfilling" do
      let(:dont_fulfill) { false }

      it "does not raise" do
        expect { result }.not_to raise_error

        but_expect_irony
      end
    end
  end

  context "when calling with call!" do
    let(:result) { klass.call!(things:, dont_fulfill:, another_thing:) }

    context "when not fulfilling" do
      let(:dont_fulfill) { true }

      it "raises" do
        expect { result }
          .to raise_error do |error|
            expect(error).to be_a UnfulfilledPromises::InteractorContractFailure
            expect(error.message).to eq(
              { something_unfulfilled: ["something_unfulfilled is missing"] }.to_json
            )
          end
      end
    end

    context "when fulfilling" do
      let(:dont_fulfill) { false }

      it "does not raise" do
        expect { result }.not_to raise_error

        but_expect_irony
      end
    end
  end

  def but_expect_irony
    expect(result.something_unfulfilled).to eq(true)
  end
end

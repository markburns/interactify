# frozen_string_literal: true

RSpec.describe Interactify::Dsl do
  self::Slot = Class.new do
    extend Interactify::Dsl
  end

  let(:slot) { self.class::Slot }

  describe ".if" do
    context "with condition, success, and failure arguments" do
      let(:return_value) { "some return value" }

      it "passes them through to the IfInteractor" do
        allow(described_class::IfInteractor).to receive(:attach_klass).and_return(return_value)

        expect(slot.if(:condition, :success, :failure)).to eq(return_value)

        expect(described_class::IfInteractor).to have_received(:attach_klass).with(
          slot,
          :condition,
          :success,
          :failure,
          caller_info: an_instance_of(String)
        )
      end

      let(:on_success1) do
        lambda { |ctx|
          ctx.success1 = true
        }
      end
      let(:on_success2) { ->(ctx) { ctx.success2 = true } }

      let(:on_failure1) { ->(ctx) { ctx.success1 = false } }
      let(:on_failure2) { ->(ctx) { ctx.success2 = false } }

      context "when the success and failure arguments are arrays" do
        it "chains the interactors" do
          klass = slot.if(
            :condition,
            [on_success1, on_success2],
            [on_failure1, on_failure2]
          )

          expect(klass.ancestors).to include Interactor
          expect(klass.ancestors).to include Interactor::Contracts

          result = klass.call!(condition: true)
          expect(result.success1).to eq(true)
          expect(result.success2).to eq(true)

          result = klass.call!(condition: false)
          expect(result.success1).to eq(false)
          expect(result.success2).to eq(false)
        end
      end

      context "when using hash then, else syntax" do
        it "chains the interactors" do
          klass = slot.if(
            :condition,
            then: [on_success1, on_success2],
            else: [on_failure1, on_failure2]
          )

          expect(klass.ancestors).to include Interactor
          expect(klass.ancestors).to include Interactor::Contracts

          result = klass.call!(condition: true)
          expect(result.success1).to eq(true)
          expect(result.success2).to eq(true)

          result = klass.call!(condition: false)
          expect(result.success1).to eq(false)
          expect(result.success2).to eq(false)
        end

        context "when unexpected keys" do
          it "raises an error" do
            expect do
              slot.if(
                :condition,
                when: [on_success1, on_success2],
                else: [on_failure1, on_failure2]
              )
            end.to raise_error(described_class::IfDefinitionUnexpectedKey, "Unexpected keys: when")
          end
        end
      end
    end
  end
end

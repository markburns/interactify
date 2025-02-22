# frozen_string_literal: true

RSpec.describe Interactify::Dsl::Organizer do
  self::DummyClass = Class.new do
    include Interactify
  end

  describe ".organize" do
    let(:result) { self.class::DummyClass.organize(*interactors) }
    let(:interactors) { [interactor1, interactor2] }

    context "with plain interactors" do
      let(:interactor1) { interactor }
      let(:interactor2) { interactor }

      it "returns the original interactor chain" do
        expect(result).to eq interactors
      end

      context "when one is a lambda" do
        let(:interactor2) { -> {} }

        it "wraps it" do
          expect(result[0]).to eq interactor1
          expect(result[1].wrapped).to eq interactor2
        end
      end

      context "when both are lambdas" do
        let(:interactor1) { -> {} }
        let(:interactor2) { -> {} }

        it "wraps it" do
          expect(result[0].wrapped).to eq interactor1
          expect(result[1].wrapped).to eq interactor2
        end
      end

      context "when wrapping a conditional" do
        self::A = Class.new do
          include Interactify

          def call
            context.a = true
          end
        end

        self::B = Class.new do
          include Interactify

          def call
            context.b = true
          end
        end

        let(:organizer) { self.class::DummyClass }

        let(:result) do
          organizer.organize(*interactors)
          organizer.call(interactor_context)
        end

        let(:interactor_context) { { this: } }
        context "without an else" do
          let(:interactors) do
            [
              {
                if: :this,
                then: self.class::A
              }
            ]
          end

          context "when the condition is true" do
            let(:this) { true }

            it "runs the then interactor" do
              expect(result.a).to eq true
              expect(result.b).to eq nil
            end
          end

          context "when the condition is false" do
            let(:this) { false }

            it "is a no-op" do
              expect(result.a).to eq nil
              expect(result.b).to eq nil
            end
          end
        end
        context "with an else" do
          let(:interactors) do
            [
              {
                if: :this,
                then: self.class::A,
                else: self.class::B
              }
            ]
          end

          context "when the condition is true" do
            let(:this) { true }

            it "runs the then interactor" do
              expect(result.a).to eq true
              expect(result.b).to eq nil
            end
          end

          context "when the condition is false" do
            let(:this) { false }

            it "runs the else interactor" do
              expect(result.a).to eq nil
              expect(result.b).to eq true
            end
          end
        end
      end

      def interactor
        Class.new do
          include Interactor
        end
      end
    end
  end
end

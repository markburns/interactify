# frozen_string_literal: true

RSpec.describe Interactify::Promising do
  describe ".validate" do
    let(:interactor) { double("interactor", promised_keys:) }

    context "with matching promise" do
      let(:promised_keys) { %i[a b c] }
      let(:promising) { %i[a b c] }

      it "returns true" do
        it_returns_true
      end
    end

    context "with missing promises" do
      let(:promised_keys) { %i[a b c] }
      let(:promising) { nil }

      it "raises an error" do
        it_raises_an_error
      end
    end

    context "with missing on both sides" do
      let(:promised_keys) { nil }
      let(:promising) { nil }

      it "returns true" do
        it_returns_true
      end
    end
    context "with unsorted keys" do
      let(:promised_keys) { %i[a b c] }
      let(:promising) { %i[c b a] }

      it "validates" do
        it_returns_true
      end
    end

    context "with extra promises" do
      let(:promised_keys) { %i[a b c] }
      let(:promising) { %i[a b c d] }

      it "raises an error" do
        it_raises_an_error
      end
    end

    context "with extra on the other side" do
      let(:promised_keys) { %i[a b c d] }
      let(:promising) { %i[a b c] }

      it "raises an error" do
        it_raises_an_error
      end
    end

    context "with mismatching promise" do
      let(:promised_keys) { %i[a b c] }
      let(:promising) { %i[a b d] }

      it "raises an error" do
        it_raises_an_error
      end
    end

    def it_raises_an_error
      expect { described_class.validate(interactor, *promising) }
        .to raise_error  do |err|
          expect(err).to be_a Interactify::MismatchingPromiseError

          expect(err.message).to eq <<~MSG.chomp
            #{interactor} does not promise:
            #{Array(promising).sort}

            Actual promises are:
            #{Array(promised_keys).sort}
          MSG
        end
    end

    def it_returns_true
      expect(described_class.validate(interactor, *promising)).to be_truthy
    end
  end
end

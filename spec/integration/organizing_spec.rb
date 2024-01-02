# frozen_string_literal: true

RSpec.describe "Interactify.organizing" do
  let(:outer_organized) { Organizing::OuterOrganizer.call! }

  context "with valid fixtures" do
    before do
      load_interactify_fixtures("organizing")
    end

    it "goes through the whole chain" do
      expect(outer_organized.deeply_nested_interactor_called).to eq(true)
      expect(outer_organized.deeply_nested_promising_interactor_called).to eq(true)
      expect(outer_organized.organized2_called).to eq(true)
    end
  end

  context "with invalid fixtures" do
    before do
      Interactify.on_definition_error(&Kernel.method(:raise))
    end

    it "spots extra interactors" do
      expect { load_interactify_fixtures("invalid_organizing/extra") }
        .to raise_error do |err|
        expect(err).to be_a Interactify::Contracts::MismatchingOrganizerError

        expect(err.message.strip).to eq(<<~MESSAGE.strip)
          Organizing::InnerOrganizer does not organize:
          [InvalidOrganizing::Extra::OuterOrganizer::Unexpected, Organizing::Organized1, Organizing::Organized2]

          Actual organized classes are:
          [Organizing::Organized1, Organizing::Organized2]

          Extra classes are:
          [InvalidOrganizing::Extra::OuterOrganizer::Unexpected]
        MESSAGE
      end
    end

    it "spots missing interactors" do
      expect { load_interactify_fixtures("invalid_organizing/missing") }
        .to raise_error do |err|
        expect(err).to be_a Interactify::Contracts::MismatchingOrganizerError

        expect(err.message.chomp).to eq(<<~MESSAGE.chomp)
          Organizing::Organized2 does not organize:
          [Organizing::DeeplyNestedInteractor, Organizing::DeeplyNestedPromisingInteractor]

          Actual organized classes are:
          [Organizing::DeeplyNestedInteractor, Organizing::DeeplyNestedPromisingInteractor, Organizing::Organized2::Organized2Called]

          Missing classes are:
          [Organizing::Organized2::Organized2Called]
        MESSAGE
      end
    end
  end
end

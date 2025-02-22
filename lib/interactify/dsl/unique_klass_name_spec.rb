# frozen_string_literal: true

RSpec.describe Interactify::Dsl::UniqueKlassName do
  describe ".for" do
    it "generates a unique class name" do
      first_name = described_class.for(SpecSupport, "Whatever")
      expect(first_name).to match(/Whatever/)
      SpecSupport.const_set(first_name, Class.new)

      second_name = described_class.for(SpecSupport, "Whatever")
      expect(second_name).to match(/Whatever_\d+/)
      expect(first_name).not_to eq(second_name)
    end

    context "when passed a qualified klass name as a prefix" do
      let(:first_name) { described_class.for(SpecSupport, "Whatever::Something", camelize:) }
      let(:camelize) { true }

      context "when camelizing" do
        let(:camelize) { true }

        it "generates a class name" do
          expect(first_name).to match(/WhateverSomething(_\d+)?/)
        end
      end

      context "when not camelizing" do
        let(:camelize) { false }

        it "generates a class name without spacing" do
          expect(first_name).to match(/Whatever__Something(_\d+)?/)
        end
      end

      it "generates a unique class name" do
        SpecSupport.const_set(first_name, Class.new)

        second_name = described_class.for(SpecSupport, "Whatever::Something")
        expect(second_name).to match(/WhateverSomething_\d+/)
        expect(first_name).not_to eq(second_name)
      end
    end
  end

  describe ".generate_unique_id (private)" do
    it "generates a random number within the specified range" do
      unique_id = described_class.send(:generate_unique_id)

      expect(unique_id).to be >= 0
      expect(unique_id).to be < 10_000
    end
  end
end

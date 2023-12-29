# frozen_string_literal: true

require "spec_helper"
require "interactify/dsl/wrapper"

RSpec.describe Interactify::Dsl::Wrapper do
  self::Organizer = Class.new { include Interactify }
  let(:organizer) { self.class::Organizer }
  let(:simple_interactor) { Class.new { include Interactify } }

  describe ".wrap_many" do
    context "when given a single interactor" do
      let(:interactors) { simple_interactor }

      it "returns an array with the plain interactor" do
        expect(described_class.wrap_many(organizer, interactors)).to all(eq(simple_interactor))
      end
    end

    context "when given an array of interactors" do
      let(:interactors) { [simple_interactor, simple_interactor] }

      it "returns an array with all interactors wrapped" do
        expect(described_class.wrap_many(organizer, interactors)).to all(eq(simple_interactor))
      end
    end

    context "when given a lambda" do
      it "wraps it in a class" do
        executable = ->(context) { context.lambda = 123 }
        result = described_class.wrap_many(organizer, [executable]).first
        expect(result).not_to eq executable
        expect(result.new).to be_a Interactify
        expect(result.wrapped).to eq executable
      end
    end
  end

  describe ".wrap" do
    context "when given a simple interactor" do
      it "returns the interactor itself" do
        expect(described_class.wrap(organizer, simple_interactor)).to eq(simple_interactor)
      end
    end
  end

  describe "#wrap_chain" do
    let(:interactor_wrapper) { described_class.new(organizer, [simple_interactor, simple_interactor]) }

    it "chains the interactors within the organizer" do
      result = interactor_wrapper.wrap_chain
      expect(result.name).to match(/#{Regexp.quote organizer.name}::Chained\d+\z/)
    end
  end

  describe "#wrap_conditional" do
    let(:conditional_interactor) { { if: -> { true }, then: simple_interactor } }

    context "when provided a valid conditional interactor" do
      let(:interactor_wrapper) { described_class.new(organizer, conditional_interactor) }

      it "wraps the conditional interactor correctly" do
        expect(interactor_wrapper.wrap_conditional.name)
          .to match(/#{Regexp.quote organizer.name}::IfProc\d+\z/)
      end
    end

    context "when missing required keys" do
      let(:invalid_interactor) { { if: -> { true } } }
      let(:interactor_wrapper) { described_class.new(organizer, invalid_interactor) }

      it "raises an ArgumentError" do
        expect { interactor_wrapper.wrap_conditional }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#wrap_proc" do
    let(:proc_interactor) { proc { |context| context } }
    let(:interactor_wrapper) { described_class.new(organizer, proc_interactor) }

    it "wraps the proc in a class that responds to call" do
      wrapped_proc = interactor_wrapper.wrap_proc
      expect(wrapped_proc).to respond_to(:call)
    end
  end
end

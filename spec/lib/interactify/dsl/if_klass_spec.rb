# frozen_string_literal: true

require "spec_helper"
require "interactify/dsl/if_klass" # Update with actual path

RSpec.describe Interactify::Dsl::IfKlass do
  subject(:if_klass) { described_class.new(if_builder) }

  let(:if_builder) do
    double("IfBuilder",
           klass_basis:,
           condition:,
           success_interactor:,
           failure_interactor:)
  end

  let(:klass_basis) do
    Class.new do
      include Interactify
    end
  end

  let(:condition) { -> { true } }
  let(:success_interactor) { -> { _1.success_invoked = true } }
  let(:failure_interactor) { -> { _1.failure_invoked = true } }

  describe "#initialize" do
    it "initializes with an if_builder" do
      expect(if_klass.if_builder).to eq(if_builder)
    end
  end

  describe "#klass" do
    it "returns a klass basis from if_builder" do
      expect(if_klass.klass).to eq(klass_basis)
    end

    context "with no expected keys" do
      it "expects no keys" do
        expect(klass_basis.expected_keys).to eq nil
      end
    end

    context "with a symbol condition" do
      let(:condition) { :egg }

      it "expects the condition" do
        expect(if_klass.klass.expected_keys).to eq [:egg]
      end
    end

    context "with a lambda condition" do
      let(:condition) { -> { _1.some_condition } }

      it "works" do
        klass = subject.klass

        result = klass.call(some_condition: true)

        expect(result.success_invoked).to eq true

        result = klass.call(some_condition: false)
        expect(result.success_invoked).to eq nil
        expect(result.failure_invoked).to eq true
      end
    end

    context "with an interactified lambda condition" do
      let(:condition) { Interactify(-> { _1.some_condition }) }

      it "works" do
        klass = subject.klass

        result = klass.call(some_condition: true)

        expect(result.success_invoked).to eq true

        result = klass.call(some_condition: false)
        expect(result.success_invoked).to eq nil
        expect(result.failure_invoked).to eq true
      end
    end

    context "with an interactified symbol to proc condition" do
      let(:condition) { Interactify(&:some_condition) }

      it "works" do
        klass = subject.klass

        result = klass.call(some_condition: true)

        expect(result.success_invoked).to eq true

        result = klass.call(some_condition: false)
        expect(result.success_invoked).to eq nil
        expect(result.failure_invoked).to eq true
      end
    end

    context "with a non matching string condition on the context" do
      let(:condition) { 'another screen' }

      it "works" do
        klass = subject.klass

        result = klass.call(some_condition: true)

        expect(result.success_invoked).to eq nil
        expect(result.failure_invoked).to eq true

        result = klass.call(some_condition: false)
        expect(result.success_invoked).to eq nil
        expect(result.failure_invoked).to eq true
      end
    end

    context "with a string condition on the context" do
      let(:condition) { 'some_condition' }

      it "works" do
        klass = subject.klass

        result = klass.call(some_condition: true)

        expect(result.success_invoked).to eq true

        result = klass.call(some_condition: false)
        expect(result.success_invoked).to eq nil
        expect(result.failure_invoked).to eq true
      end
    end

    context "with a symbol condition on the context" do
      let(:condition) { :some_condition }

      it "works" do
        klass = subject.klass

        result = klass.call(some_condition: true)

        expect(result.success_invoked).to eq true

        result = klass.call(some_condition: false)
        expect(result.success_invoked).to eq nil
        expect(result.failure_invoked).to eq true
      end
    end
  end
end

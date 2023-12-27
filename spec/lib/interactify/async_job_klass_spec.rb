# frozen_string_literal: true

RSpec.describe Interactify::AsyncJobKlass do
  let(:container_klass) { double("ContainerKlass", expected_keys:, promised_keys:, optional_attrs:) }
  let(:optional_attrs) { [] }
  let(:expected_keys) { [] }
  let(:promised_keys) { [] }
  let(:klass_suffix) { "Suffix" }
  let(:method_name) { :call! }

  subject do
    described_class.new(
      container_klass:,
      klass_suffix:
    )
  end

  describe "#async_job_klass" do
    it "returns an Interactor class" do
      async_job_klass = subject.async_job_klass

      expect(async_job_klass).to be_a(Class)
      expect(async_job_klass.included_modules).to include(Interactor)
    end

    it "defines singleton methods call and call!" do
      async_job_klass = subject.async_job_klass

      expect(async_job_klass.singleton_methods).to include(:call, :call!)
    end
  end

  describe "#args" do
    let(:context) { double("Context", to_h: { "foo" => "bar" }) }

    context "when container_klass responds to :expected_keys" do
      before do
        allow(container_klass).to receive(:expected_keys) { [:foo] }
      end

      it "restricts keys based on contract and optional attributes" do
        result = subject.args(context)

        expect(result).to eq("foo" => "bar")
      end
    end

    context "when container_klass does not respond to :expected_keys" do
      before do
        allow(container_klass).to receive(:respond_to?).and_return true
        allow(container_klass).to receive(:respond_to?).with(:expected_keys).and_return(false)
      end

      it "returns args without any restrictions" do
        result = subject.args(context)

        expect(result).to eq("foo" => "bar")
      end
    end
  end

  describe "private methods" do
    let(:async_job_klass) { Class.new { include Interactor } }

    describe "#attach_call" do
      it "defines a :call singleton method on the async job class" do
        subject.send(:attach_call, async_job_klass)

        expect(async_job_klass.singleton_methods).to include(:call)
      end
    end

    describe "#attach_call!" do
      it "defines a :call! singleton method on the async job class" do
        subject.send(:attach_call!, async_job_klass)

        expect(async_job_klass.singleton_methods).to include(:call!)
      end
    end

    describe "#restrict_to_optional_or_keys_from_contract" do
      let(:args) { { "foo" => "bar", "extra" => "value" } }
      let(:contract_keys) { ["foo"] }
      let(:optional_keys) { ["baz"] }

      before do
        allow(container_klass).to receive(:expected_keys) { contract_keys + optional_keys }
      end

      it "restricts keys based on contract and optional attributes" do
        result = subject.send(:restrict_to_optional_or_keys_from_contract, args)

        expect(result).to eq("foo" => "bar")
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Interactify::Async::JobKlass do
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

    context "with empty context" do
      let(:empty_context) { double("EmptyContext", to_h: {}) }

      before do
        allow(container_klass).to receive(:respond_to?).with(:expected_keys).and_return(true)
        allow(container_klass).to receive(:expected_keys).and_return([])
        allow(container_klass).to receive(:optional_attrs).and_return([])
      end

      it "returns an empty hash" do
        result = subject.args(empty_context)

        expect(result).to eq({})
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

      context "when calling with empty context" do
        let(:job_klass) { class_double("JobClass", perform_async: true) }
        let(:empty_context) { double("EmptyContext", to_h: {}) }

        before do
          allow(container_klass).to receive(:const_get).with("Job#{klass_suffix}").and_return(job_klass)
          allow(subject).to receive(:args).with(empty_context).and_return({})
          subject.send(:attach_call!, async_job_klass)
        end

        it "calls perform_async with empty hash correctly" do
          async_job_klass.call!(empty_context)

          expect(job_klass).to have_received(:perform_async).with(no_args)
        end
      end

      context "when calling with empty args" do
        let(:job_klass) { class_double("JobClass") }
        let(:empty_context) { double("EmptyContext", to_h: {}) }

        before do
          allow(container_klass).to receive(:const_get).with("Job#{klass_suffix}").and_return(job_klass)
          allow(subject).to receive(:args).with(empty_context).and_return({})
          subject.send(:attach_call!, async_job_klass)
        end

        it "calls perform_async with no keyword arguments" do
          # This test verifies the actual implementation detail of how empty hashes are passed
          expect(job_klass).to receive(:perform_async)

          async_job_klass.call!(empty_context)
        end

        it "handles empty hash correctly without double splat operator issues" do
          # This test specifically checks for the issue with parameterless interactors
          allow(job_klass).to receive(:perform_async) do |**kwargs|
            # This will raise an error if kwargs is not properly handled
            expect(kwargs).to eq({})
          end

          expect { async_job_klass.call!(empty_context) }.not_to raise_error
        end

        it "reproduces the issue with double splat on empty hash" do
          # This test demonstrates the issue with parameterless interactors
          # In some Ruby versions, **{} can cause issues

          # Mock the implementation to match the actual code
          allow(job_klass).to receive(:method_missing) do |method_name, **kwargs|
            if method_name == :perform_async
              # This would be the actual implementation in Sidekiq
              # The issue is that **{} can be problematic
              expect(kwargs).to eq({})
            else
              super(method_name, **kwargs)
            end
          end

          # This should not raise an error, but might in some Ruby versions
          expect { async_job_klass.call!(empty_context) }.not_to raise_error
        end

        it "calls perform_async without arguments when args is empty" do
          # This test verifies our fix for the empty hash issue
          expect(job_klass).to receive(:perform_async).with(no_args)

          async_job_klass.call!(empty_context)
        end
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

        result = subject.send(:restrict_to_optional_or_keys_from_contract, { "baz" => 1, "extra" => 2 })
        expect(result).to eq("baz" => 1)
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Interactify::Async::JobKlass do
  let(:container_klass) do
    Class.new do
      include Interactify

      class << self
        attr_reader :called_with

        def call!(**context)
          @called_with = context
        end

        def expected_keys
          %i[id name]
        end
      end
    end
  end

  let(:klass_suffix) { "WithSuffix" }
  let(:job_klass) { described_class.new(container_klass: container_klass, klass_suffix: klass_suffix) }
  let(:async_job_klass) { job_klass.async_job_klass }

  before do
    # Define the Job class that would normally be created by Interactify
    container_klass.const_set("Job#{klass_suffix}", Class.new do
      include Sidekiq::Job if Interactify.sidekiq?

      class << self
        attr_reader :perform_async_called, :perform_async_args

        def perform_async(*args)
          @perform_async_called = true
          @perform_async_args = args.empty? ? nil : args.first
        end

        def reset!
          @perform_async_called = false
          @perform_async_args = nil
        end
      end
    end)
  end

  after do
    # Clean up the dynamically created constants
    container_klass.send(:remove_const, "Job#{klass_suffix}") if container_klass.const_defined?("Job#{klass_suffix}")
  end

  describe "#async_job_klass" do
    it "creates a class that includes Interactor and Interactor::Contracts" do
      expect(async_job_klass.included_modules).to include(Interactor)
      expect(async_job_klass.included_modules).to include(Interactor::Contracts)
    end

    it "attaches call and call! methods" do
      expect(async_job_klass).to respond_to(:call)
      expect(async_job_klass).to respond_to(:call!)
    end
  end

  describe "handling of context parameters" do
    let(:job_with_suffix) { container_klass.const_get("Job#{klass_suffix}") }

    before do
      job_with_suffix.reset!
    end

    context "with empty payload" do
      it "calls perform_async with no arguments" do
        async_job_klass.call!

        expect(job_with_suffix.perform_async_called).to be true
        expect(job_with_suffix.perform_async_args).to be_nil
      end
    end

    context "with payload data" do
      it "calls perform_async with the provided arguments" do
        async_job_klass.call!(id: 123, name: "test")

        expect(job_with_suffix.perform_async_called).to be true

        actual_args = if job_with_suffix.perform_async_args.is_a?(Hash)
                        job_with_suffix.perform_async_args.transform_keys(&:to_sym)
                      else
                        job_with_suffix.perform_async_args
                      end

        expect(actual_args).to eq({ id: 123, name: "test" })
      end

      it "restricts arguments to expected keys from contract" do
        async_job_klass.call!(id: 123, name: "test", unexpected: "value")

        expect(job_with_suffix.perform_async_called).to be true

        expected_args = { id: 123, name: "test" }

        actual_keys = if job_with_suffix.perform_async_args.is_a?(Hash)
                        job_with_suffix.perform_async_args.keys.map(&:to_sym)
                      else
                        []
                      end

        expect(actual_keys).to match_array(expected_args.keys)
        expect(actual_keys).not_to include(:unexpected)
      end
    end

    context "when using call instead of call!" do
      it "delegates to call!" do
        expect(async_job_klass).to receive(:call!).with(id: 123)
        async_job_klass.call(id: 123)
      end
    end
  end
end

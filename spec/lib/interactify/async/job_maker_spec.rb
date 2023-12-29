# frozen_string_literal: true

RSpec.describe Interactify::Async::JobMaker do
  let(:container_klass) { double("ContainerKlass", expected_keys:, promised_keys:, optional_attrs:) }
  let(:optional_attrs) { [] }
  let(:expected_keys) { [] }
  let(:promised_keys) { [] }
  let(:opts) { { queue: "default" } }
  let(:klass_suffix) { "Suffix" }
  let(:method_name) { :call! }

  subject do
    described_class.new(
      container_klass:,
      opts:,
      klass_suffix:,
      method_name:
    )
  end

  if Interactify.sidekiq
    describe "#initialize" do
      it "initializes with expected attributes" do
        expect(subject.container_klass).to eq(container_klass)
        expect(subject.opts).to eq(opts)
        expect(subject.method_name).to eq(method_name)
        expect(subject.klass_suffix).to eq(klass_suffix)
      end
    end
  end

  describe "concerning JobClass" do
    describe "#job_klass" do
      if Interactify.sidekiq
        it "returns a job class" do
          job_klass = subject.job_klass

          expect(job_klass).to be_a(Class)
        end
        it "job class includes Sidekiq::Job" do
          job_klass = subject.job_klass

          expect(job_klass.included_modules).to include(Sidekiq::Job)
        end
      else
        it "returns a null job_klass" do
          job_klass = subject.job_klass

          expect(job_klass).to eq(Interactify::NullJob)
        end
      end
    end
  end

  if Interactify.sidekiq
    describe "concerning JobClass" do
      describe "#job_klass" do
        it "job class includes JOBABLE_OPTS constant" do
          job_klass = subject.job_klass

          expect(job_klass.const_defined?(:JOBABLE_OPTS)).to be true
          expect(job_klass::JOBABLE_OPTS).to eq(opts)
        end

        it "job class includes JOBABLE_METHOD_NAME constant" do
          job_klass = subject.job_klass

          expect(job_klass.const_defined?(:JOBABLE_METHOD_NAME)).to be true
          expect(job_klass::JOBABLE_METHOD_NAME).to eq(method_name)
        end
      end
    end
  end
end

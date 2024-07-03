# frozen_string_literal: true

if Interactify.sidekiq?
  # rubocop:disable Naming/MethodParameterName
  RSpec.describe Interactify::Async::Jobable do
    class self::TestNoArgs
      include Interactify::Async::Jobable

      interactor_job

      def self.call!
        []
      end
    end

    class self::TestPositionalArgs
      include Interactify::Async::Jobable

      interactor_job

      def self.call!(a, b, c = 5)
        [a, b, c]
      end
    end

    class self::TestKeywordArgs
      include Interactify::Async::Jobable

      interactor_job

      def self.call!(a:, b:, c: 10)
        [a, b, c]
      end
    end

    class self::TestAsyncInteractor
      include Interactify

      expect :a, :b
      optional :c
    end

    class self::TestInheritanceBaseInteractify
      include Interactify

      def call
        self.class.module_parent::GlobalSideEffects.set self.class, "base class"
      end
    end

    class self::TestSubClassInteractify < self::TestInheritanceBaseInteractify
      def call
        self.class.module_parent::GlobalSideEffects.set self.class, "sub class"
      end
    end

    class self::TestSubSubClassInteractify < self::TestSubClassInteractify
      def call
        self.class.module_parent::GlobalSideEffects.set self.class, "sub sub class"
      end
    end

    class self::TestDifferentParams
      include Interactify

      interactor_job(opts: { queue: :different_queue }, klass_suffix: "DifferentParams")
    end

    it "can make a job with different params" do
      expect(self.class::TestDifferentParams::JobDifferentParams::JOBABLE_OPTS[:queue]).to eq(:different_queue)
    end

    it "can make a job that accepts no args" do
      expect(self.class::TestNoArgs::Job.new.perform).to eq([])
    end

    it "can make a job that accepts positional args" do
      expect(self.class::TestPositionalArgs::Job.new.perform(1, 2)).to eq([1, 2, 5])
    end

    it "can make a job that accepts keyword args" do
      expect(self.class::TestKeywordArgs::Job.new.perform(a: 2, b: 4)).to eq([2, 4, 10])
    end

    context "with an async interactor" do
      let(:job_klass) { self.class::TestAsyncInteractor::Job }
      let(:async_class) { self.class::TestAsyncInteractor::Async }

      before do
        allow(job_klass).to receive(:perform_async)
      end

      it "can make an async interactor job" do
        async_class.call(a: 2, b: 4)

        expect(job_klass).to have_received(:perform_async).with("a" => 2, "b" => 4)
      end

      it "ignores the unexpected arguments from the context" do
        async_class.call(a: 2, b: 4, some_unexpected_arg: Object.new)

        expect(job_klass).to have_received(:perform_async).with("a" => 2, "b" => 4)
      end

      it "supports optional args" do
        async_class.call(a: 2, b: 4, c: 6)

        expect(job_klass).to have_received(:perform_async).with("a" => 2, "b" => 4, "c" => 6)
      end
    end

    class self::GlobalSideEffects
      def self.set(key, value)
        @values ||= {}
        @values[key] = value
      end

      def self.get(key)
        @values[key]
      end

      def self.reset
        @values = nil
      end
    end

    it "can make a job that inherits from a base interactor" do
      # although this uses shared global state it's wiped out before and after this example
      self.class.tap do |k|
        side_effects = k::GlobalSideEffects
        side_effects.reset

        base = k::TestInheritanceBaseInteractify
        sub = k::TestSubClassInteractify
        sub_sub = k::TestSubSubClassInteractify

        expect(sub::Job).not_to eq base::Job
        expect(sub_sub::Job).not_to eq base::Job
        expect(sub_sub::Job).not_to eq sub::Job

        [base, sub, sub_sub].each do |klass|
          klass::Job.new.perform
        end

        Sidekiq::Job.drain_all

        expect(side_effects.get(base)).to eq("base class")
        expect(side_effects.get(sub)).to eq("sub class")
        expect(side_effects.get(sub_sub)).to eq("sub sub class")
      ensure
        side_effects.reset
      end
    end

    describe "#job_calling" do
      context "with basic setup" do
        class self::TestJobCalling
          include Interactify::Async::Jobable
          job_calling method_name: :custom_method

          def self.custom_method
            "method called"
          end
        end

        it "creates a job class that can call the specified method" do
          job_instance = self.class::TestJobCalling::Job.new
          expect(job_instance.perform).to eq("method called")
        end
      end

      context "with custom options and class suffix" do
        class self::TestJobWithOptions
          include Interactify::Async::Jobable
          job_calling method_name: :parameter_method, opts: { queue: "custom_queue" }, klass_suffix: "Custom"

          def self.parameter_method(param)
            param
          end
        end

        it "applies custom options to the job class" do
          expect(self.class::TestJobWithOptions::JobCustom::JOBABLE_OPTS[:queue]).to eq("custom_queue")
        end

        it "creates a job class with the specified suffix" do
          job_instance = self.class::TestJobWithOptions::JobCustom.new
          expect(job_instance.perform("test")).to eq("test")
        end
      end

      context "integration with Sidekiq" do
        before do
          allow(Sidekiq::Worker).to receive(:perform_async)
        end

        class self::TestJobWithSidekiq
          include Interactify::Async::Jobable

          job_calling method_name: :sidekiq_method

          def self.sidekiq_method
            "sidekiq method"
          end
        end

        it "enqueues job to Sidekiq" do
          self.class::TestJobWithSidekiq::Job.perform_async

          enqueued = Sidekiq::Job.jobs.last

          expect(enqueued).to match(
            a_hash_including(
              "retry" => true,
              "queue" => "default",
              "class" => self.class::TestJobWithSidekiq::Job.to_s
            )
          )
        end
      end
    end
  end
end
# rubocop:enable Naming/MethodParameterName

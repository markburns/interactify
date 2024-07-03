# frozen_string_literal: true

if Interactify.sidekiq?
  RSpec.describe Interactify do
    describe ".with" do
      let(:klass_with_options) { k(:Optionified) }
      let(:result) { organizer.call!(choose_life:) }

      context "when setting options" do
        let(:constants) { klass_with_options.constants }
        let(:async_klass_name) { constants.detect { _1 =~ /Async/ } }
        let(:async_klass) { klass_with_options.const_get(async_klass_name) }
        let(:job_klass_name) { constants.detect { _1 =~ /Job/ } }

        let(:job_klass) do
          klass_with_options.const_get(
            job_klass_name
          )
        end

        it "calls the underlying job class" do
          expect(job_klass.name).to match(/Optionified::Job__Queue_Within30Seconds__Retry_3(_\d+)?/)
          expect(job_klass).to receive(:perform_async).with(
            hash_including("choose_life" => true)
          )

          expect(async_klass.name).to match(/Optionified::Async__Queue_Within30Seconds__Retry_3(_\d+)?/)
          async_klass.call!("choose_life" => true)
          Sidekiq::Worker.drain_all
        end
      end

      module self::SomeNamespace
        class Optionified
          include Interactify.with(
            queue: "within_30_seconds",
            retry: 3
          )
          expect :choose_life, filled: false

          def call
            context.life = true
          end
        end
      end

      def k(klass)
        self.class::SomeNamespace.const_get(klass)
      end
    end
  end
end

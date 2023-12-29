# frozen_string_literal: true

require "interactify/async/job_maker"

module Interactify
  module Async
    module Jobable
      extend ActiveSupport::Concern

      # e.g. if Klass < Base
      # and Base has a Base::Job class
      #
      # then let's make sure to define Klass::Job separately
      included do |base|
        next if Interactify.sidekiq_missing?

        def base.inherited(klass)
          super_klass = klass.superclass
          super_job = super_klass::Job # really spiffing

          opts = super_job::JOBABLE_OPTS
          jobable_method_name = super_job::JOBABLE_METHOD_NAME

          to_call = defined?(super_klass::Async) ? :interactor_job : :job_calling

          klass.send(to_call, opts:, method_name: jobable_method_name)
          super(klass)
        end
      end

      class_methods do
        # create a Job class and an Async class
        # see job_calling for details on the Job class
        #
        # the Async class is a wrapper around the Job class
        # that allows it to be used in an interactor chain
        #
        # E.g.
        #
        # class ExampleInteractor
        #   include Interactify
        #   expect :foo
        #
        #   include Jobable
        #   interactor_job
        # end
        #
        # doing the following will immediately enqueue a job
        # that calls the interactor ExampleInteractor with (foo: 'bar')
        # ExampleInteractor::Async.call(foo: 'bar')
        #
        # it will also ensure to pluck only the expects from the context
        # so that you can have other non primitive values in the context
        # but the job will only have the expects passed to it
        #
        # obviously you will need to be aware that later interactors
        # in an interactor chain cannot depend on the result of the async
        # interactor
        def interactor_job(method_name: :call!, opts: {}, klass_suffix: "")
          job_maker = JobMaker.new(container_klass: self, opts:, method_name:, klass_suffix:)
          # with WhateverInteractor::Job you can perform the interactor as a job
          # from sidekiq
          # e.g. WhateverInteractor::Job.perform_async(...)
          const_set("Job#{klass_suffix}", job_maker.job_klass)

          # with WhateverInteractor::Async you can call WhateverInteractor::Job
          # in an organizer oro on its oen using normal interactor call call! semantics
          # e.g. WhateverInteractor::Async.call(...)
          #      WhateverInteractor::Async.call!(...)
          const_set("Async#{klass_suffix}", job_maker.async_job_klass)
        end

        # if this was defined in ExampleClass this creates the following class
        # ExampleClass::Job
        # this class ia added as a convenience so you can easily turn a
        # class method into a job
        #
        # Example:
        #
        # class ExampleClass
        #   include Jobable
        #   job_calling method_name: :some_method
        # end
        #
        # # the following class is created that you can use to enqueue a job
        # in the sidekiq yaml file
        # ExampleClass::Job.some_method
        def job_calling(method_name:, opts: {}, klass_suffix: "")
          job_maker = JobMaker.new(container_klass: self, opts:, method_name:, klass_suffix:)

          const_set("Job#{klass_suffix}", job_maker.job_klass)
        end
      end
    end
  end
end

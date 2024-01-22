# frozen_string_literal: true

require "interactify/async/jobable"
require "interactify/contracts/call_wrapper"
require "interactify/contracts/failure"
require "interactify/contracts/setup"
require "interactify/contracts/promising"
require "interactify/contracts/organizing"
require "interactify/contracts/breaches"
require "interactify/dsl/organizer"

module Interactify
  module Contracts
    module Helpers
      extend ActiveSupport::Concern

      # rubocop: disable Metrics/BlockLength
      class_methods do
        def expect(*attrs, filled: true)
          Setup.expects(context: self, attrs:, filled:)
        end

        def promise(*attrs, filled: true, should_delegate: true)
          Setup.promises(context: self, attrs:, filled:, should_delegate:)
        end

        def promising(*args)
          Promising.validate(self, *args)
        end

        def organizing(*args)
          Organizing.validate(self, *args)
        end

        def promised_keys
          _interactify_extract_keys(contract.promises)
        end

        def expected_keys
          _interactify_extract_keys(contract.expectations)
        end

        def optional(*attrs)
          @optional_attrs ||= []
          @optional_attrs += attrs

          delegate(*attrs, to: :context)
        end

        attr_reader :optional_attrs

        private

        # this is the most brittle part of the code, relying on
        # interactor-contracts internals
        # so extracted it to here so change is isolated
        def _interactify_extract_keys(clauses)
          clauses.instance_eval { @terms }.json&.rules&.keys
        end
      end
      # rubocop: enable Metrics/BlockLength

      included do
        failure_klass = Class.new(Contracts::Failure)
        # example self is Whatever::SomeInteractor
        # failure class:  Whatever::SomeInteractor::InteractorContractFailure
        const_set "InteractorContractFailure", failure_klass
        prepend Contracts::CallWrapper
        include Dsl::Organizer

        on_breach do |breaches|
          if @_interactor_called_by_non_bang_method == true
            Breaches.handle_with_failure(context, breaches)
          else
            Breaches.handle_with_exception(context, failure_klass, breaches)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "interactify/async/jobable"
require "interactify/contracts/call_wrapper"
require "interactify/contracts/failure"
require "interactify/contracts/setup"
require "interactify/contracts/promising"
require "interactify/contracts/organizing"
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
        c = Class.new(Contracts::Failure)
        # example self is Whatever::SomeInteractor
        # failure class:  Whatever::SomeInteractor::InteractorContractFailure
        const_set "InteractorContractFailure", c
        prepend Contracts::CallWrapper
        include Dsl::Organizer

        on_breach do |breaches|
          breaches = breaches.map { |b| { b.property => b.messages } }.inject(&:merge)

          Interactify.trigger_contract_breach_hook(context, breaches)

          if @_interactor_called_by_non_bang_method == true
            context.fail! contract_failures: breaches
          else
            # e.g. raises
            # SomeNamespace::SomeClass::ContractFailure, {whatever: 'is missing'}
            # but also sending the context into Sentry
            exception = c.new(breaches.to_json)
            Interactify.trigger_before_raise_hook(exception)
            raise exception
          end
        end
      end
    end
  end
end

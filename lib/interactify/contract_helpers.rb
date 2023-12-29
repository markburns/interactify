# frozen_string_literal: true

require "interactify/jobable"
require "interactify/call_wrapper"
require "interactify/organizer"
require "interactify/contract_failure"
require "interactify/setup_contract"

module Interactify
  module ContractHelpers
    extend ActiveSupport::Concern

    class_methods do
      def expect(*attrs, filled: true)
        SetupContract.setup_expects(context: self, attrs:, filled:)
      end

      def promise(*attrs, filled: true, should_delegate: true)
        SetupContract.setup_promises(context: self, attrs:, filled:, should_delegate:)
      end

      def optional(*attrs)
        @optional_attrs ||= []
        @optional_attrs += attrs

        delegate(*attrs, to: :context)
      end

      attr_reader :optional_attrs
    end

    included do
      c = Class.new(ContractFailure)
      # example self is Whatever::SomeInteractor
      # failure class:  Whatever::SomeInteractor::InteractorContractFailure
      const_set "InteractorContractFailure", c
      prepend CallWrapper
      include Organizer

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

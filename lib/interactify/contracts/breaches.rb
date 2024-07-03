# frozen_string_literal: true

module Interactify
  module Breaches
    def self.handle_with_failure(context, breaches)
      breaches = preamble(context, breaches)
      context.fail! contract_failures: breaches
    end

    def self.handle_with_exception(context, failure_klass, breaches)
      breaches = preamble(context, breaches)

      # e.g. raises
      # SomeNamespace::SomeClass::ContractFailure, {whatever: 'is missing'}
      # but also sending the context into Sentry
      exception = failure_klass.new(breaches.to_json)
      Interactify.trigger_before_raise_hook(exception)
      raise exception
    end

    def self.preamble(context, breaches)
      breaches = breaches.map { |b| { b.property => b.messages } }.inject(&:merge)

      Interactify.trigger_contract_breach_hook(context, breaches)
      breaches
    end
  end
end

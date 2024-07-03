# frozen_string_literal: true

module Interactify
  module Hooks
    def reset
      @on_contract_breach = nil
      @before_raise_hook = nil
      @configuration = nil
    end

    def trigger_contract_breach_hook(...)
      @on_contract_breach&.call(...)
    end

    def on_contract_breach(&block)
      @on_contract_breach = block
    end

    def trigger_before_raise_hook(...)
      @before_raise_hook&.call(...)
    end

    def before_raise(&block)
      @before_raise_hook = block
    end
  end
end

# frozen_string_literal: true

module Interactify
  class Configuration
    attr_writer :root

    def root
      @root ||= fallback
    end

    def fallback
      Rails.root / "app" if Interactify.railties?
    end

    def trigger_definition_error(error)
      @on_definition_error&.call(error)
    end

    def on_definition_error(handler = nil, &block)
      @on_definition_error = block_given? ? block : handler
    end
  end
end

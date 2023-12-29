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
  end
end

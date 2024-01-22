module Interactify
  class << self
    delegate :on_definition_error, :trigger_definition_error, to: :configuration

    def railties_missing?
      @railties_missing
    end

    def railties_missing!
      @railties_missing = true
    end

    def railties
      railties?
    end

    def railties?
      !railties_missing?
    end

    def sidekiq_missing?
      @sidekiq_missing
    end

    def sidekiq_missing!
      @sidekiq_missing = true
    end

    def sidekiq
      sidekiq?
    end

    def sidekiq?
      !sidekiq_missing?
    end
  end
end

Interactify.instance_eval do
  @sidekiq_missing = nil
  @railties_missing = nil
end

begin
  require "sidekiq"
rescue LoadError
  Interactify.sidekiq_missing!
end

begin
  require "rails/railtie"
rescue LoadError
  Interactify.railties_missing!
end



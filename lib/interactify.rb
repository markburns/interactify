# frozen_string_literal: true

require "interactor"
require "bigdecimal"
require "interactor-contracts"
require "active_support/all"

require "interactify/version"
require "interactify/contracts/helpers"
require "interactify/contracts/promising"
require "interactify/dsl"
require "interactify/wiring"
require "interactify/configuration"
require "interactify/interactify_callable"
require "interactify/dependency_inference"
require "interactify/hooks"
require "interactify/configure"
require "interactify/with_options"

module Interactify
  extend ActiveSupport::Concern
  extend Hooks
  extend Configure

  class << self
    delegate :root, to: :configuration

    def included(base)
      # call `with` without arguments to get default Job and Async classes
      base.include(with)
    end

    def with(sidekiq_opts = {})
      Module.new do
        define_singleton_method :included do |receiver|
          WithOptions.new(receiver, sidekiq_opts).setup
        end
      end
    end
  end
end

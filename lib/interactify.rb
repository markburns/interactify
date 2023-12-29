# frozen_string_literal: true

require "interactor"
require "interactor-contracts"
require "active_support/all"

require "interactify/version"
require "interactify/contracts/helpers"
require "interactify/contracts/promising"
require "interactify/dsl"
require "interactify/wiring"
require "interactify/configuration"

module Interactify
  def self.railties_missing?
    @railties_missing
  end

  def self.railties_missing!
    @railties_missing = true
  end

  def self.railties
    railties?
  end

  def self.railties?
    !railties_missing?
  end

  def self.sidekiq_missing?
    @sidekiq_missing
  end

  def self.sidekiq_missing!
    @sidekiq_missing = true
  end

  def self.sidekiq
    sidekiq?
  end

  def self.sidekiq?
    !sidekiq_missing?
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

module Interactify
  extend ActiveSupport::Concern

  class << self
    def validate_app(ignore: [])
      Interactify::Wiring.new(root: Interactify.configuration.root, ignore:).validate_app
    end

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

    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    delegate :root, to: :configuration
  end

  included do |base|
    base.extend Interactify::Dsl

    base.include Interactor::Organizer
    base.include Interactor::Contracts
    base.include Interactify::Contracts::Helpers

    # defines two classes on the receiver class
    # the first is the job class
    # the second is the async class
    # the async class is a wrapper around the job class
    # that allows it to be used in an interactor chain
    #
    # E.g.
    #
    # class ExampleInteractor
    #  include Interactify
    #  expect :foo
    # end
    #
    # ExampleInteractor::Job is a class availabe to be used in a sidekiq yaml file
    #
    # doing the following will immediately enqueue a job
    # that calls the interactor ExampleInteractor with (foo: 'bar')
    #
    # ExampleInteractor::Async.call(foo: 'bar')
    include Interactify::Async::Jobable
    interactor_job
  end

  def called_klass_list
    context._called.map(&:class)
  end
end

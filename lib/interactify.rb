# frozen_string_literal: true

require "interactor"
require "interactor-contracts"
require "active_support/all"

require "interactify/version"
require "interactify/contract_helpers"
require "interactify/dsl"
require "interactify/interactor_wiring"
require "interactify/promising"

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
      Interactify::InteractorWiring.new(root: Interactify.configuration.root, ignore:).validate_app
    end

    def sidekiq_missing?
      @sidekiq_missing
    end

    def sidekiq_missing!
      @sidekiq_missing = true
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
    base.include Interactify::ContractHelpers

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
    include Interactify::Jobable
    interactor_job
  end

  class_methods do
    def promising(*args)
      Promising.validate(self, *args)
    end

    def promised_keys
      _interactify_extract_keys(contract.promises)
    end

    def expected_keys
      _interactify_extract_keys(contract.expectations)
    end

    private

    # this is the most brittle part of the code, relying on
    # interactor-contracts internals
    # so extracted it to here so change is isolated
    def _interactify_extract_keys(clauses)
      clauses.instance_eval { @terms }.json&.rules&.keys
    end
  end

  class Configuration
    attr_writer :root

    def root
      @root ||= fallback
    end

    def fallback
      Rails.root / "app" if Interactify.railties?
    end
  end

  def called_klass_list
    context._called.map(&:class)
  end
end

# frozen_string_literal: true

require 'interactor'
require 'interactor-contracts'
require 'rails'
require 'active_support/all'

require 'interactify/version'
require 'interactify/contract_helpers'
require 'interactify/dsl'
require 'interactify/interactor_wiring'

module Interactify
  extend ActiveSupport::Concern

  class << self
    def validate_app(ignore: [])
      Interactify::InteractorWiring.new(root: Interactify.configuration.root, ignore:).validate_app
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

  class Configuration
    attr_writer :root

    def root
      @root ||= Rails.root / 'app'
    end
  end

  def called_klass_list
    context._called.map(&:class)
  end
end

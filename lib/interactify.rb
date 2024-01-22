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
require "interactify/interactify_callable"
require "interactify/dependency_inference"
require "interactify/hooks"
require "interactify/configure"

module Interactify
  extend ActiveSupport::Concern
  extend Hooks
  extend Configure

  class << self
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

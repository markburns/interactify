# frozen_string_literal: true

module Interactify
  module Core
    extend ActiveSupport::Concern

    included do |base|
      base.extend Interactify::Dsl

      base.include Interactor::Organizer
      base.include Interactor::Contracts
      base.include Interactify::Contracts::Helpers
    end

    def called_klass_list
      context._called.map(&:class)
    end
  end
end

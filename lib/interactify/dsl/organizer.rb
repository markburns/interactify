# frozen_string_literal: true

require "interactify/dsl/wrapper"

module Interactify
  module Dsl
    module Organizer
      extend ActiveSupport::Concern

      class_methods do
        def organize(*interactors)
          wrapped = Wrapper.wrap_many(self, interactors)

          super(*wrapped)
        end
      end

      def call
        self.class.organized.each do |interactor|
          instance = interactor.new(context)

          instance.instance_variable_set(
            :@_interactor_called_by_non_bang_method,
            @_interactor_called_by_non_bang_method
          )

          instance.tap(&:run!)
        end
      end
    end
  end
end

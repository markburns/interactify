module Interactify
  module OrganizerCallMonkeyPatch
    extend ActiveSupport::Concern

    class_methods do
      def organize(*interactors)
        wrapped = wrap_lambdas_in_interactors(interactors)

        super(*wrapped)
      end

      def wrap_lambdas_in_interactors(interactors)
        Array(interactors).map do |interactor|
          case interactor
          when Proc
            Class.new do
              include Interactify

              define_method(:call) do
                interactor.call(context)
              end
            end
          else
            interactor
          end
        end
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

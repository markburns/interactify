# frozen_string_literal: true

require "interactify/dsl/unique_klass_name"

module Interactify
  module Dsl
    class Wrapper
      attr_reader :organizer, :interactor

      def self.wrap_many(organizer, interactors)
        Array(interactors).map do |interactor|
          wrap(organizer, interactor)
        end
      end

      def self.wrap(organizer, interactor)
        new(organizer, interactor).wrap
      end

      def initialize(organizer, interactor)
        @organizer = organizer
        @interactor = interactor
      end

      def wrap
        case interactor
        when Hash
          wrap_conditional
        when Array
          wrap_chain
        when Proc
          wrap_proc
        when Class
          return interactor if interactor < Interactor

          raise ArgumentError, "#{interactor} must respond_to .call" unless interactor.respond_to?(:call)

          wrap_proc
        else
          interactor
        end
      end

      def wrap_chain
        return self.class.wrap(organizer, interactor.first) if interactor.length == 1

        klass_name = UniqueKlassName.for(organizer, "Chained")
        organizer.chain(klass_name, *interactor.map { self.class.wrap(organizer, _1) })
      end

      def wrap_conditional
        raise ArgumentError, "Hash must have at least :if, and :then key" unless condition && then_do

        return organizer.if(condition, then_do, else_do) if else_do

        organizer.if(condition, then_do)
      end

      def condition = interactor[:if]
      def then_do = interactor[:then]
      def else_do = interactor[:else]

      def wrap_proc
        this = self

        Class.new do
          include Interactify

          define_singleton_method :wrapped do
            this.interactor
          end

          define_method(:call) do
            this.interactor.call(context)
          end
        end
      end
    end
  end
end

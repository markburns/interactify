# frozen_string_literal: true

require "interactify/each_chain"
require "interactify/if_interactor"
require "interactify/unique_klass_name"

module Interactify
  module Dsl
    # creates a class in the attach_klass_to's namespace
    # e.g.
    #
    # in Orders
    # Interactify.each(self, :packages, A, B, C)
    #
    # will create a class called Orders::EachPackage, that
    # will call the interactor chain A, B, C for each package in the context
    def each(plural_resource_name, *each_loop_klasses)
      EachChain.attach_klass(
        self,
        plural_resource_name,
        *each_loop_klasses
      )
    end

    def if(condition, succcess_interactor, failure_interactor = nil)
      IfInteractor.attach_klass(
        self,
        condition,
        succcess_interactor,
        failure_interactor
      )
    end

    # this method allows us to dynamically create
    # an organizer from a name, and a chain of interactors
    #
    # e.g.
    #
    # Interactify.chain(:SomeClass, A, B, C, expect: [:foo, :bar])
    #
    # is the programmable equivalent to
    #
    # class SomeClass
    #   include Interactify
    #   organize(A, B, C)
    # end
    #
    # it will attach the generate class to the currenct class and
    # use the class name passed in
    # rubocop:disable all
    def chain(klass_name, *chained_klasses, expect: [])
      expectations = expect

      klass = Class.new do                             # class EvaluatingNamespace::SomeClass
        include Interactify                            #   include Interactify
        expect(*expectations) if expectations.any?     #   expect :foo, :bar

        define_singleton_method(:source_location) do   #   def self.source_location
          source_location                              #     [file, line]
        end                                            #   end

        organize(*chained_klasses)                     #   organize(A, B, C)
      end                                              # end

      # attach the class to the calling namespace
      where_to_attach = self.binding.receiver
      klass_name = UniqueKlassName.for(where_to_attach, klass_name)
      where_to_attach.const_set(klass_name, klass)
    end
  end
end

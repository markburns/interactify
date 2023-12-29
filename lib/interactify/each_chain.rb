# frozen_string_literal: true
require 'interactify/unique_klass_name'

module Interactify
  class EachChain
    attr_reader :each_loop_klasses, :plural_resource_name, :evaluating_receiver

    def self.attach_klass(evaluating_receiver, plural_resource_name, *each_loop_klasses)
      iteratable = new(each_loop_klasses, plural_resource_name, evaluating_receiver)
      iteratable.attach_klass
    end

    def initialize(each_loop_klasses, plural_resource_name, evaluating_receiver)
      @each_loop_klasses = each_loop_klasses
      @plural_resource_name = plural_resource_name
      @evaluating_receiver = evaluating_receiver
    end

    # allows us to dynamically create an interactor chain
    # that iterates over the packages and
    # uses the passed in each_loop_klasses
    # rubocop:disable all
    def klass
      this = self

      Class.new do                                                                    # class SomeNamespace::EachPackage
        include Interactify                                          #   include Interactify

        expects do                                                                    #   expects do
          required(this.plural_resource_name)                                         #     required(:packages)
        end                                                                           #   end

        define_singleton_method(:source_location) do                                  #   def self.source_location
          const_source_location this.evaluating_receiver.to_s                                     #     [file, line]
        end                                                                           #   end

        define_method(:run!) do                                                       #  def run!
          context.send(this.plural_resource_name).each_with_index do |resource, index|#    context.packages.each_with_index do |package, index|
            context[this.singular_resource_name] = resource                           #       context.package = package
            context[this.singular_resource_index_name] = index                        #       context.package_index = index

            klasses = InteractorWrapper.wrap_many(self, this.each_loop_klasses)

            klasses.each do |interactor|                                              #       [A, B, C].each do |interactor|
              interactor.call!(context)                                               #         interactor.call!(context)
            end                                                                       #       end
          end                                                                         #     end

          context[this.singular_resource_name] = nil                                  #     context.package = nil
          context[this.singular_resource_index_name] = nil                            #     context.package_index = nil

          context                                                                     #     context
        end                                                                           #   end

        define_method(:inspect) do
          "<#{this.namespace}::#{this.iterator_klass_name} iterates_over: #{this.each_loop_klasses.inspect}>"
        end
      end
    end
    # rubocop:enable all

    def attach_klass
      name = iterator_klass_name

      namespace.const_set(name, klass)
      namespace.const_get(name)
    end

    def namespace
      evaluating_receiver
    end

    def iterator_klass_name
      prefix = "Each#{singular_resource_name.to_s.camelize}"

      UniqueKlassName.for(namespace, prefix)
    end

    def singular_resource_name
      plural_resource_name.to_s.singularize.to_sym
    end

    def singular_resource_index_name
      "#{singular_resource_name}_index".to_sym
    end
  end
end

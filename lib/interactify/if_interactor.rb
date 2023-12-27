# frozen_string_literal: true

module Interactify
  class IfInteractor
    attr_reader :condition, :success_interactor, :failure_interactor, :evaluating_receiver

    def self.attach_klass(evaluating_receiver, condition, succcess_interactor, failure_interactor)
      ifable = new(evaluating_receiver, condition, succcess_interactor, failure_interactor)
      ifable.attach_klass
    end

    def initialize(evaluating_receiver, condition, succcess_interactor, failure_interactor)
      @evaluating_receiver = evaluating_receiver
      @condition = condition
      @success_interactor = succcess_interactor
      @failure_interactor = failure_interactor
    end

    # allows us to dynamically create an interactor chain
    # that iterates over the packages and
    # uses the passed in each_loop_klasses
    # rubocop:disable all
    def klass
      this = self

      Class.new do                                                           
        include Interactor                                                    
        include Interactor::Contracts                                          

        expects do                                                              
          required(this.condition) unless this.condition.is_a?(Proc)
        end                                                                       

        define_singleton_method(:source_location) do                               
          const_source_location this.evaluating_receiver.to_s                                     #     [file, line]
        end                                                                          

        define_method(:run!) do                                                       
          result = this.condition.is_a?(Proc) ? this.condition.call(context) : context.send(this.condition)
          interactor = result ? this.success_interactor : this.failure_interactor
          interactor&.respond_to?(:call!) ? interactor.call!(context) : interactor&.call(context)
        end

        define_method(:inspect) do
          "<#{this.namespace}::#{this.if_klass_name} #{this.condition} ? #{this.success_interactor} : #{this.failure_interactor}>"
        end
      end
    end
    # rubocop:enable all

    def attach_klass
      namespace.const_set(if_klass_name, klass)
      namespace.const_get(if_klass_name)
    end

    def namespace
      evaluating_receiver
    end

    def if_klass_name
      name = condition.is_a?(Proc) ? "Proc" : condition

      "If#{name.to_s.camelize}".to_sym
    end
  end
end

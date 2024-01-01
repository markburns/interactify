# frozen_string_literal: true

RSpec.describe Interactify::Dsl::EachChain do
  describe ".attach_klass" do
    it "attaches a new class to the passed in context" do
      chain = Interactify::Dsl::EachChain.attach_klass(SpecSupport, :things, [k(:A), k(:B)])

      expect(chain.name).to match(/SpecSupport::EachThing\d+/)

      result = chain.call!(things: [1, 2, 3])
      expect(result.things).to eq([1, 2, 3])
      expect(result.a).to eq(:A)
      expect(result.b).to eq(:B)
    end

    context "when expected key is missing in context" do
      it "raises an error" do
        chain = Interactify::Dsl::EachChain.attach_klass(SpecSupport, :things, [k(:A), k(:B)])

        expect { chain.call!(other_things: [1, 2, 3]) }
          .to raise_error do |error|
          expect(error).to be_a described_class::MissingIteratableValueInContext

          expect(error.message.strip).to eq(<<~MESSAGE.strip)
            Expected `context.things`: nil
            to respond to :each_with_index
          MESSAGE
        end
      end
    end

    def k(name)
      @klasses ||= {}

      @klasses[name] ||= Class.new do
        include Interactify

        define_method :call do
          context.send("#{name.to_s.downcase}=", name)
        end

        define_singleton_method(:name) do
          name.to_s
        end
      end
    end
  end
end

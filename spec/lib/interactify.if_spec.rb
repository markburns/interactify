# frozen_string_literal: true

RSpec.describe Interactify do
  describe ".if" do
    let(:organizer) { k(:Choice) }
    let(:result) { organizer.call!(choose_life:) }

    context "when choosing life" do
      let(:choose_life) { true }

      it "chooses life" do
        expect(result.life).to eq(true)
      end
    end

    context "when choosing not life" do
      let(:choose_life) { false }

      it "chooses not life" do
        expect(result.life).to eq(false)
      end
    end

    module self::SomeNamespace
      Life = Class.new do
        include Interactify

        def call
          context.life = true
        end
      end

      NotLife = Class.new do
        include Interactify

        def call
          context.life = false
        end
      end

      Choice = Class.new do
        include Interactify

        organize self.if :choose_life, Life, NotLife
      end
    end

    def k(klass)
      self.class::SomeNamespace.const_get(klass)
    end
  end
end

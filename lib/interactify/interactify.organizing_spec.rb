# frozen_string_literal: true

RSpec.describe "Interactify.organizing" do
  describe ".organizing" do
    module self::SomeNamespace
      C = Interactify do |c|
        c.c = "c"
      end

      D = Interactify do |c|
        c.d = "d"
      end

      B = Class.new do
        include Interactify
        organize C

        def call
          context.b = "b"
        end
      end

      A = Class.new do
        include Interactify
        organize B

        def call
          context.a = "a"
        end
      end

      Multi = Class.new do
        include Interactify
        organize B, C, D

        def call; end
      end

      WithoutOrganizing = Class.new do
        include Interactify

        organize A, B
      end

      ValidOrganizing = Class.new do
        include Interactify

        organize \
          A.organizing(B),
          B.organizing(C)
      end

      MultipleOrganizing = Class.new do
        include Interactify

        organize \
          Multi.organizing(B, C, D)
      end
    end

    def k(klass)
      self.class::SomeNamespace.const_get(klass)
    end

    it "supports optional organizing calls" do
      expect(k(:WithoutOrganizing).call!.a).to eq("a")
      expect(k(:WithoutOrganizing).call!.b).to eq("b")
    end

    it "supports organizing calls" do
      expect(k(:ValidOrganizing).call!.a).to eq("a")
      expect(k(:ValidOrganizing).call!.b).to eq("b")
    end

    context "with invalid organizing assertions" do
      before do
        @errors = []

        Interactify.on_definition_error do |err|
          @errors << err
        end
      end

      it "raises a loadtime error when a organize is not matching" do
        this = self

        expect_class_definition = lambda do
          Class.new do
            include Interactify

            organize \
              this.k(:A).organizing(this.k(:B)),
              this.k(:B).organizing(this.k(:D))
          end
        end

        expect_class_definition.call
        error = @errors[0]
        expect(error).to be_a Interactify::Contracts::MismatchingOrganizerError

        expect(error.message.strip).to eq <<~MESSAGE.strip
          #{k(:B)} does not organize:
          [#{k(:D)}]

          Actual organized classes are:
          [#{k(:C)}]

          Missing classes are:
          [#{k(:C)}]

          Extra classes are:
          [#{k(:D)}]
        MESSAGE
      end
    end
  end
end

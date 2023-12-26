# frozen_string_literal: true

RSpec.describe 'Interactify.promising' do
  describe '.promising' do
    module self::SomeNamespace
      A = Class.new do
        include Interactify
        promise :a

        def call
          context.a = 'a'
        end
      end

      B = Class.new do
        include Interactify
        promise :b

        def call
          context.b = 'b'
        end
      end

      Multi = Class.new do
        include Interactify
        promise :a, :b, :c

        def call
          context.a = 'a'
          context.b = 'b'
          context.c = 'c'
        end
      end

      WithoutPromising = Class.new do
        include Interactify

        organize A, B
      end

      ValidPromising = Class.new do
        include Interactify

        organize \
          A.promising(:a),
          B.promising(:b)
      end

      MultiplePromising = Class.new do
        include Interactify

        organize \
          Multi.promising(:a, :b, :c)
      end
    end

    def k(klass)
      self.class::SomeNamespace.const_get(klass)
    end

    it 'supports optional promising calls' do
      expect(k(:WithoutPromising).call!.a).to eq('a')
      expect(k(:WithoutPromising).call!.b).to eq('b')
    end

    it 'supports promising calls' do
      expect(k(:ValidPromising).call!.a).to eq('a')
      expect(k(:ValidPromising).call!.b).to eq('b')
    end

    it 'raises a loadtime error when a promise is not matching' do
      this = self

      expect {
        Class.new do
          include Interactify

          organize \
            this.k(:A).promising(:a),
            this.k(:B).promising(:c)
        end
      }.to raise_error(Interactify::MismatchingPromiseError) do |error|
        expect(error.message).to eq <<~MESSAGE.chomp
          #{k(:B)} does not promise:
          [:c]

          Actual promises are:
          [:b]
        MESSAGE
      end
    end
  end
end

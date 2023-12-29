# frozen_string_literal: true

require "interactify/rspec/matchers"

RSpec.describe "rspec matchers" do
  describe "expect_inputs" do
    it "passes when the inputs are correct" do
      expect(k(:A)).to expect_inputs(:a)
      expect(k(:A)).not_to expect_inputs(:b)

      expect(k(:B)).to expect_inputs(:b)
      expect(k(:B)).not_to expect_inputs(:a)

      expect(k(:P)).not_to expect_inputs(:a, :b)
    end

    it "shows failure messages" do
      expect { expect(k(:A)).to expect_inputs(:b) }.to raise_error do |error|
        expect(error.message).to include("SomeNamespace::A to expect inputs [:b]")
        expect(error.message).to include("missing inputs: [:b]")
        expect(error.message).to include("extra inputs: [:a]")
      end
    end

    it "works with vanilla interactors without blowing up" do
      expect(k(:Vanilla)).not_to expect_inputs(:a)
    end
  end

  describe "promise_outputs" do
    it "passes when the outputs are correct" do
      expect(k(:A)).not_to promise_outputs(:a)
      expect(k(:A)).not_to promise_outputs(:a)

      expect(k(:P)).to promise_outputs(:a, :b, :c)
    end

    it "shows failure messages" do
      expect { expect(k(:A)).to promise_outputs(:b) }.to raise_error do |error|
        expect(error.message).to include("SomeNamespace::A to promise outputs [:b]")
        expect(error.message).to include("missing outputs: [:b]")
        expect(error.message).to include("extra outputs: []")
      end
    end
    it "works with vanilla interactors without blowing up" do
      expect(k(:Vanilla)).not_to promise_outputs(:a)
    end
  end

  describe "#organize_interactors" do
    it "passes when the interactors are correct" do
      expect(k(:O)).to organize_interactors(k(:A), k(:B))
      expect(k(:O)).not_to organize_interactors(k(:B), k(:P))
      expect(k(:O)).not_to organize_interactors(k(:A), k(:B), k(:P))
    end

    it "shows failure messages" do
      expect { expect(k(:O)).to organize_interactors(k(:B), k(:P)) }.to raise_error do |error|
        expect(error.message).to include("SomeNamespace::O to organize interactors [#{k(:B)}, #{k(:P)}]")
        expect(error.message).to include("missing interactors: [#{k(:P)}]")
        expect(error.message).to include("extra interactors: [#{k(:A)}]")
      end
    end
  end

  module self::SomeNamespace
    Vanilla = Class.new do
      include Interactor
    end

    A = Class.new do
      include Interactify
      expect :a
    end

    B = Class.new do
      include Interactify
      expect :b
    end

    P = Class.new do
      include Interactify
      promise :a, :b, :c
    end

    O = Class.new do
      include Interactify
      organize A, B
    end
  end

  def k(klass)
    self.class::SomeNamespace.const_get(klass)
  end
end

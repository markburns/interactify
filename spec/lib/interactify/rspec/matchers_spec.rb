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

    it "works with vanilla interactors without blowing up" do
      expect(k(:Vanilla)).not_to promise_outputs(:a)
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
  end

  def k(klass)
    self.class::SomeNamespace.const_get(klass)
  end
end

# frozen_string_literal: true

RSpec.describe "Interactify.if" do
  before do
    files = Dir.glob("./spec/fixtures/integration_app/app/interactors/if/**/*.rb")
    files.each do |file|
      require file
    end
  end

  let(:thing1) do
    OpenStruct.new
  end

  let(:thing2) do
    OpenStruct.new
  end

  context "with an interactified symbol to proc" do
    before do
      require "./spec/fixtures/integration_app/app/interactors/if_with_interactified_lambda_clause"
    end

    it "successfully runs" do
      klass = A::B::IfWithInteractifiedLambdaClause
      # result = klass.call!(some_flag_is_set: true)
      # expect(result.was_set).to eq(true)

      result = klass.call!(some_flag_is_set: false)
      expect(result.was_set).to eq(false)
    end
  end

  context "with alternative method syntax" do
    let(:truthy_result) { If::AlternativeMethodSyntaxOrganizer.call!(blah: true) }
    let(:falsey_result) { If::AlternativeMethodSyntaxOrganizer.call!(blah: false) }

    it "runs the relevant clauses" do
      expect(truthy_result.a).to eq("a")
      expect(truthy_result.b).to eq("b")
      expect(truthy_result.c).to eq(nil)
      expect(truthy_result.d).to eq(nil)
      expect(truthy_result.anyways).to eq(true)

      expect(falsey_result.a).to eq(nil)
      expect(falsey_result.b).to eq(nil)
      expect(falsey_result.c).to eq("c")
      expect(falsey_result.d).to eq("d")
      expect(falsey_result.anyways).to eq(false)
    end
  end

  context "with hash syntax" do
    let(:truthy_result) { If::HashSyntaxOrganizer.call!(blah: true) }
    let(:falsey_result) { If::HashSyntaxOrganizer.call!(blah: false) }

    it "runs the relevant clauses" do
      expect(truthy_result.a).to eq("a")
      expect(truthy_result.b).to eq("b")
      expect(truthy_result.c).to eq(nil)
      expect(truthy_result.d).to eq(nil)
      expect(truthy_result.anyways).to eq(true)

      expect(falsey_result.a).to eq(nil)
      expect(falsey_result.b).to eq(nil)
      expect(falsey_result.c).to eq("c")
      expect(falsey_result.d).to eq("d")
      expect(falsey_result.anyways).to eq(false)
    end
  end
end

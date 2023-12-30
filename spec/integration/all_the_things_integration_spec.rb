# frozen_string_literal: true

RSpec.describe "Interactify" do
  let(:things) do
    [thing1, thing2]
  end

  let(:thing1) do
    OpenStruct.new
  end

  let(:thing2) do
    OpenStruct.new
  end

  before do
    require_files("each/")
    require_files("if/")
    require_files('')
  end

  context 'without an optional thing' do
    let(:result) { AllTheThings.promising(:a).call!(things:, optional_thing: false) }

    it "sets A and B, then lambda_set, then both_a_and_b, then first_more_thing, next_more_thing" do
      expect(result.a).to eq("a")
      expect(result.b).to eq("b")
      expect(result.c).to eq(nil)
      expect(result.d).to eq(nil)
      expect(result.lambda_set).to eq(true)
      expect(result.both_a_and_b).to eq(true)
      expect(result.more_things).to eq([1, 2, 3, 4])
      expect(result.first_more_thing).to eq(true)
      expect(result.next_more_thing).to eq(true)
      expect(result.optional_thing_was_set).to eq(false)
    end
  end

  context "with an optional thing" do
    let(:result) { AllTheThings.promising(:a).call!(things:, optional_thing: true) }

    it "sets A and B, then lambda_set, then both_a_and_b, then first_more_thing, next_more_thing" do
      expect(result.a).to eq("a")
      expect(result.b).to eq("b")
      expect(result.c).to eq(nil)
      expect(result.d).to eq(nil)
      expect(result.lambda_set).to eq(true)
      expect(result.both_a_and_b).to eq(true)
      expect(result.more_things).to eq([6, 7, 8, 9])
      expect(result.first_more_thing).to eq(true)
      expect(result.next_more_thing).to eq(true)
      expect(result.optional_thing_was_set).to eq(true)
    end
  end

  def require_files(dir)
    files = Dir.glob("./spec/fixtures/integration_app/app/interactors/#{dir}**/*.rb")

    files.each do |file|
      require file
    end
  end
end

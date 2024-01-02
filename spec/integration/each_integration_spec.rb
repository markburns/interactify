# frozen_string_literal: true

RSpec.describe "Interactify.each" do
  before do
    files = Dir.glob("./spec/fixtures/integration_app/app/interactors/each/**/*.rb")
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

  it "runs the outer interactors" do
    result = Each::Organizer.call!(things: [thing1, thing2])

    expect(result.a).to eq("a")
    expect(result.b).to eq("b")
    expect(result.c).to eq("c")
    expect(result.d).to eq("d")
  end
end

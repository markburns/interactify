# frozen_string_literal: true

RSpec.describe Interactify::InteractorWiring do
  subject do
    described_class.new(
      root: File.expand_path(root)
    )
  end

  let(:root) do
    Pathname.new("./spec/fixtures/dummy_app/app/")
  end

  before do
    Dir.glob("#{root}**/*.rb").each { |f| require(f) }
  end

  def f(path)
    File.expand_path("spec/fixtures/dummy_app/app/interactors/#{path}.rb").to_s
  end

  it "finds all the interactor files" do
    expected = [
      f("dummy_interactify"),
      f("dummy_interactor_1"),
      f("dummy_interactor_2"),
      f("dummy_interactor_3"),
      f("dummy_interactor_4"),
      f("within_namespace/one"),
      f("within_namespace/two"),
      f("within_namespace/three")
    ]

    expect(subject.interactor_files).to match_array expected
  end

  it "determines the organizer files" do
    expected = [
      f("dummy_organizer"),
      f("dummy_interactor_interactify_organizer"),
      f("within_namespace/organizer")
    ]

    expect(subject.organizer_files).to match_array expected
  end

  it "validates the organizers" do
    callable = subject.organizers.detect { |o| o.klass == DummyOrganizer }

    error_context = callable.validate_callable
    expect(error_context.missing_keys).to eq({})
  end

  it "validates the namespaced organizers" do
    callable = subject.organizers.detect { |o| o.klass == WithinNamespace::Organizer }
    callable.validate_callable

    [
      "#{root / '/within_namespace/one.rb'} missing keys: foo",
      "#{root / '/within_namespace/two.rb'} missing keys: phoo"
    ]
  end
end

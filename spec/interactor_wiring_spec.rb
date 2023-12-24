RSpec.describe Interactify::InteractorWiring do
  subject do
    # by default namespace is unnecessary, but allows for isolation of
    # SpecSupport::DummyOrganizer etc files from the application
    described_class.new(
      root: File.expand_path(root),
      namespace: 'SpecSupport'
    )
  end

  let(:root) do
    Pathname.new('./spec/fixtures/dummy_app/')
  end

  before do
    Dir.glob("#{root}**/*.rb").each { |f| require(f) }
  end

  def f(path)
    File.expand_path("spec/fixtures/dummy_app/#{path}.rb").to_s
  end

  it 'finds all the interactor files' do
    expected = [
      f('dummy_interactor_1'),
      f('dummy_interactor_2'),
      f('dummy_interactor_3'),
      f('dummy_interactor_4'),
      f('within_namespace/one'),
      f('within_namespace/two'),
      f('within_namespace/three')
    ]

    expect(subject.interactor_files).to match_array expected
  end

  it 'determines the organizer files' do
    expected = [
      f('dummy_organizer'),
      f('within_namespace/organizer')
    ]

    expect(subject.organizer_files).to match_array expected
  end

  it 'validates the organizers' do
    callable = subject.organizers.detect { |o| o.klass == SpecSupport::DummyOrganizer }

    error_context = callable.validate_callable
    expect(error_context.missing_keys).to eq({})
  end

  it 'validates the namespaced organizers' do
    callable = subject.organizers.detect { |o| o.klass == SpecSupport::WithinNamespace::Organizer }
    callable.validate_callable

    [
      "#{root / '/within_namespace/one.rb'} missing keys: foo",
      "#{root / '/within_namespace/two.rb'} missing keys: phoo"
    ]
  end
end

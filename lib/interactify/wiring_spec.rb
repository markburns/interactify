# frozen_string_literal: true

RSpec.describe Interactify::Wiring do
  subject do
    described_class.new(
      root: File.expand_path(root)
    )
  end

  let(:root) do
    Pathname.new("./spec/fixtures/dummy_app/app/")
  end

  before do
    Dir.glob("#{root}**/*.rb").each { |f| silence_warnings { require(f) } }
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

  describe "#validate_app" do
    context "with a valid app" do
      let(:root) do
        Pathname.new("./spec/fixtures/dummy_app/app/")
      end

      it "validates the app" do
        expect(subject.validate_app).to eq ""
      end
    end

    context "with an invalid app" do
      let(:root) do
        Pathname.new("./spec/fixtures/integration_app/app/")
      end

      it "returns the errors" do
        expect(subject.validate_app).to eq ""
      end
    end
  end

  describe "#ignore_klass?" do
    self::DummyInteractor = Class.new do
      include Interactify
    end

    let(:klass) { self.class::DummyInteractor }
    let(:wiring) { described_class.new(root:, ignore:) }
    let(:result) { wiring.send(:ignore_klass?, wiring.ignore, klass) }

    def self.it_ignores
      it "ignores" do
        expect(result).to be true
      end
    end

    context "with an array of classes" do
      let(:ignore) { [klass] }

      it_ignores
    end

    context "with a regexp" do
      let(:ignore) { [/Dummy/] }

      it_ignores
    end

    context "with a string" do
      let(:ignore) { ["DummyInteractor"] }

      it_ignores
    end

    context "proc condition" do
      let(:ignore) { [->(k) { k.to_s =~ /DummyInteractor/ }] }

      it_ignores
    end

    context "empty ignore" do
      let(:ignore) { [] }

      it "does not ignore class" do
        expect(result).to be false
      end
    end
  end
  context "with errors" do
    let(:organizer1) { double("Organizer1", klass: "SomeOrganizer1") }
    let(:organizer2) { double("Organizer2", klass: "SomeOrganizer2") }

    let(:interactor1) { double("Interactor1", klass: "SomeInteractor1") }
    let(:interactor2) { double("Interactor2", klass: "SomeInteractor2") }
    let(:interactor3) { double("Interactor3", klass: "SomeInteractor3") }

    describe "#format_error" do
      let(:missing_keys) { %i[foo bar] }
      let(:interactor) { double("Interactor", klass: "SomeInteractor") }
      let(:organizer) { double("Organizer", klass: "SomeOrganizer") }
      let(:formatted_errors) { [] }

      it "formats the error message correctly" do
        subject.send(:format_error, missing_keys, interactor, organizer, formatted_errors)
        expect(formatted_errors.first).to include("Missing keys: :foo, :bar")
        expect(formatted_errors.first).to include("expected in: SomeInteractor")
        expect(formatted_errors.first).to include("called by: SomeOrganizer")
      end
    end

    describe "#format_errors" do
      it "formats and combines all errors" do
        all_errors = {
          organizer1 => double(
            "ErrorContext",
            missing_keys: {
              interactor1 => %i[key1 key2]
            }
          ),
          organizer2 => double(
            "ErrorContext",
            missing_keys: {
              interactor2 => [:key3]
            }
          )
        }

        expect(subject).to receive(:format_error).twice.and_call_original
        formatted_error_string = subject.format_errors(all_errors)
        expect(formatted_error_string).to include("Missing keys: :key1, :key2")
        expect(formatted_error_string).to include("Missing keys: :key3")
        expect(formatted_error_string).to match(/expected in:.*\n\s+called by:/)
      end
    end

    describe "#each_error" do
      it "yields each error unless the class is ignored" do
        all_errors = {
          organizer1 => double(
            "ErrorContext",
            missing_keys: {
              interactor1 => [:key1],
              interactor2 => [:key2]
            }
          ),
          organizer2 => double(
            "ErrorContext",
            missing_keys: {
              interactor3 => [:key3]
            }
          )
        }

        allow(subject).to receive(:ignore_klass?).and_return(false)

        expect { |b| subject.each_error(all_errors, &b) }
          .to yield_successive_args(
            [[:key1], anything, anything],
            [[:key2], anything, anything],
            [[:key3], anything, anything]
          )
      end

      it "does not yield errors for ignored classes" do
        all_errors = {
          organizer1 => double(
            "ErrorContext",
            missing_keys: {
              interactor1 => [:key1]
            }
          )
        }
        allow(subject).to receive(:ignore_klass?).and_return(true)
        expect { |b| subject.each_error(all_errors, &b) }.not_to yield_control
      end
    end
  end
end

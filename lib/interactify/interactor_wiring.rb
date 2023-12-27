# frozen_string_literal: true

require "active_support/all"

require "interactify/interactor_wiring/callable_representation"
require "interactify/interactor_wiring/constants"
require "interactify/interactor_wiring/files"

module Interactify
  class InteractorWiring
    attr_reader :root, :ignore

    def initialize(root: Rails.root, ignore: [])
      @root = root.to_s.gsub(%r{/$}, "")
      @ignore = ignore
    end

    def validate_app
      errors = organizers.each_with_object({}) do |organizer, all_errors|
        next if ignore_klass?(ignore, organizer.klass)

        errors = organizer.validate_callable
        all_errors[organizer] = errors
      end

      format_errors(errors)
    end

    def format_errors(all_errors)
      formatted_errors = []

      each_error(all_errors) do |missing, interactor, organizer|
        format_error(missing, interactor, organizer, formatted_errors)
      end

      formatted_errors.join("\n\n")
    end

    def each_error(all_errors)
      all_errors.each do |organizer, error_context|
        next if ignore_klass?(ignore, organizer.klass)

        error_context.missing_keys.each do |interactor, missing|
          next if ignore_klass?(ignore, interactor.klass)

          yield missing, interactor, organizer
        end
      end
    end

    def format_error(missing, interactor, organizer, formatted_errors)
      formatted_errors << <<~ERROR
        Missing keys: #{missing.to_a.map(&:to_sym).map(&:inspect).join(', ')}
         expected in: #{interactor.klass}
           called by: #{organizer.klass}
      ERROR
    end

    def ignore_klass?(ignore, klass)
      case ignore
      when Array
        ignore.any? { ignore_klass?(_1, klass) }
      when Regexp
        klass.to_s =~ ignore
      when String
        klass.to_s[ignore]
      when Proc
        ignore.call(klass)
      when Class
        klass <= ignore
      end
    end

    delegate :organizers, :interactors, :interactor_lookup, to: :constants

    def constants
      @constants ||= Constants.new(
        root:,
        organizer_files:,
        interactor_files:
      )
    end

    delegate :organizer_files, :interactor_files, to: :files

    def files
      @files ||= Files.new(root:)
    end
  end
end

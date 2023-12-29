# frozen_string_literal: true

module Interactify
  class Wiring
    class Files
      attr_reader :root

      def initialize(root:)
        @root = root
      end

      def organizer_files
        possible_files.select { |_, contents| organizer_file?(contents) }.map(&:first).sort
      end

      def interactor_files
        possible_files.select { |_, contents| interactor_file?(contents) }.map(&:first).sort
      end

      private

      def organizer_file?(code)
        organizer?(code) && (interactified?(code) || vanilla_organizer?(code))
      end

      def interactor_file?(code)
        !organizer?(code) && (interactified?(code) || vanilla_interactor?(code))
      end

      def vanilla_organizer?(code)
        code[/include Interactor::Organizer/]
      end

      def vanilla_interactor?(code)
        code[/include Interactor$/]
      end

      def interactified?(code)
        code["include Interactify"]
      end

      def organizer?(code)
        code[/^\s+organize/]
      end

      def possible_files
        @possible_files ||= Dir.glob("#{root}/**/*.rb").map { |f| [f, File.read(f)] }
      end
    end
  end
end

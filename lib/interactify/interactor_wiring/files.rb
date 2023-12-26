module Interactify
  class InteractorWiring
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

      def organizer_file?(file_contents)
        (file_contents['include Interactify'] || file_contents[/include Interactor::Organizer/]) &&
          file_contents[/^\s+organize/]
      end

      def interactor_file?(file_contents)
        file_contents['include Interactify'] ||
          file_contents[/include Interactor$/]
      end

      def possible_files
        @possible_files ||= Dir.glob("#{root}/**/*.rb").map { |f| [f, File.read(f)] }
      end
    end
  end
end

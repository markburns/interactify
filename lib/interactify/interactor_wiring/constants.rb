module Interactify
  class InteractorWiring
    class Constants
      attr_reader :root, :namespace, :organizer_files, :interactor_files

      def initialize(root:, namespace:, organizer_files:, interactor_files:)
        @root = root.is_a?(Pathname) ? root : Pathname.new(root)
        @namespace = namespace
        @organizer_files = organizer_files
        @interactor_files = interactor_files
      end

      def organizers
        @organizers ||= organizer_files.flat_map do |f|
          callables_in_file(f)
        end.compact.select(&:organizer?)
      end

      def interactors
        @interactors ||= interactor_files.flat_map do |f|
          callables_in_file(f)
        end.compact.reject(&:organizer?)
      end

      def interactor_lookup
        @interactor_lookup ||= (interactors + organizers).index_by(&:klass)
      end

      private

      def callables_in_file(f)
        @callables_in_file ||= {}

        @callables_in_file[f] ||= _callables_in_file(f)
      end

      def _callables_in_file(f)
        constant = constant_for(f)
        return if constant == Interactify

        internal_klasses = internal_constants_for(constant)

        ([constant] + internal_klasses).map { |k| new_callable(f, k, self) }
      end

      def internal_constants_for(constant)
        constant
          .constants
          .map { |sym| constant_from_symbol(constant, sym) }
          .select { |pk| interactor_klass?(pk) }
      end

      def constant_from_symbol(constant, symbol)
        constant.module_eval do
          symbol.to_s.constantize
        rescue StandardError
          "#{constant.name}::#{symbol}".constantize rescue nil
        end
      end

      def interactor_klass?(object)
        return unless object.is_a? Class

        object.ancestors.include?(Interactor) || object.ancestors.include?(Interactor::Organizer)
      end

      def new_callable(filename, klass, wiring)
        CallableRepresentation.new(filename:, klass:, wiring:)
      end

      def constant_for(filename)
        require filename

        underscored_klass_name = underscored_klass_name_without_outer_namespace(filename)
        underscored_klass_name = trim_rails_design_pattern_folder underscored_klass_name

        klass_name = underscored_klass_name.classify

        should_pluralize = filename[underscored_klass_name.pluralize]
        klass_name = klass_name.pluralize if should_pluralize

        outer_namespace_constant.const_get(klass_name)
      end

      # Example:
      # trim_rails_folder("app/interactors/namespace/sub_namespace/class_name.rb")
      # => "namespace/sub_namespace/class_name.rb"
      def trim_rails_design_pattern_folder(filename)
        rails_folders.each do |folder|
          regexable_folder = Regexp.quote("#{folder}/")
          regex = /^#{regexable_folder}/

          return filename.gsub(regex, '') if filename.match?(regex)
        end

        filename
      end

      def rails_folders = Dir.glob(root / '*').map { Pathname.new _1 }.select(&:directory?).map { |f| File.basename(f) }


      # Example:
      # "/home/code/something/app/interactors/namespace/sub_namespace/class_name.rb"
      # "/namespace/sub_namespace/class_name.rb"
      #  ['', 'namespace', 'sub_namespace', 'class_name.rb']
      #  ['namespace', 'sub_namespace', 'class_name.rb']
      # remove outernamespace (SpecSupport)
      def underscored_klass_name_without_outer_namespace(filename)
        filename.to_s # "/home/code/something/app/interactors/namespace/sub_namespace/class_name.rb"
          .gsub(root.to_s, '')   # "/namespace/sub_namespace/class_name.rb"
          .gsub('/concerns', '') #  concerns directory is ignored by Zeitwerk
          .split('/')            # "['', 'namespace', 'sub_namespace', 'class_name.rb']
          .compact_blank         # "['namespace', 'sub_namespace', 'class_name.rb']
          .reject.with_index { |segment, i| i.zero? && segment == namespace }
          .join('/')             # 'namespace/sub_namespace/class_name.rb'
          .gsub(/\.rb\z/, '')     # 'namespace/sub_namespace/class_name'
      end

      def outer_namespace_constant
        @outer_namespace_constant ||= Object.const_get(namespace)
      end
    end
  end
end

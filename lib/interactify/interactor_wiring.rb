require 'active_support/all'

module Interactify
  class InteractorWiring
    attr_reader :root, :namespace, :ignore

    def initialize(root: Rails.root, namespace: 'Object', ignore: [])
      @root = root.to_s.gsub(%r{/$}, '')
      @namespace = namespace
      @ignore = ignore
    end

    concerning :Validation do
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

        all_errors.each do |organizer, error_context|
          next if ignore_klass?(ignore, organizer.klass)

          error_context.missing_keys.each do |interactor, missing|
            next if ignore_klass?(ignore, interactor.klass)

            formatted_errors << <<~ERROR
              Missing keys: #{missing.to_a.map(&:to_sym).map(&:inspect).join(', ')}
                        in: #{interactor.klass}
                       for: #{organizer.klass}
            ERROR
          end
        end

        formatted_errors.join("\n\n")
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
    end

    class CallableRepresentation
      attr_reader :filename, :klass, :wiring

      delegate :interactor_lookup, to: :wiring

      def initialize(filename:, klass:, wiring:, organizer: nil)
        @filename = filename
        @klass = klass
        @wiring = wiring
      end

      def validate_callable(error_context: ErrorContext.new)
        if organizer?
          assign_previously_defined(error_context: error_context)
          validate_children(error_context: error_context)
        end

        validate_self(error_context: error_context)
      end

      def promised_keys
        Array(klass.contract.promises.instance_eval { @terms }.json&.rules&.keys)
      end

      def expected_keys
        Array(klass.contract.expectations.instance_eval { @terms }.json&.rules&.keys)
      end

      def all_keys
        expected_keys.concat(promised_keys)
      end

      def inspect
        "#<#{self.class.name}#{object_id} @filename=#{filename}, @klass=#{klass.name}>"
      end

      def organizer?
        klass.respond_to?(:organized)
      end

      def assign_previously_defined(error_context:)
        return unless contract?

        error_context.append_previously_defined_keys(all_keys)
      end

      def validate_children(error_context:)
        klass.organized.each do |interactor|
          nested_callable = interactor_lookup[interactor]
          next if nested_callable.nil?

          error_context = nested_callable.validate_callable(error_context: error_context)
        end

        error_context
      end

      private

      def contract?
        klass.ancestors.include? Interactor::Contracts
      end

      def validate_self(error_context:)
        return error_context unless contract?

        error_context.infer_missing_keys(self)
        error_context.add_promised_keys(promised_keys)
        error_context
      end
    end

    class ErrorContext
      def previously_defined_keys
        @previously_defined_keys ||= Set.new
      end

      def append_previously_defined_keys(keys)
        keys.each do |key|
          previously_defined_keys << key
        end
      end

      def missing_keys
        @missing_keys ||= {}
      end

      def add_promised_keys(promised_keys)
        promised_keys.each do |key|
          previously_defined_keys << key
        end
      end

      def infer_missing_keys(callable)
        new_keys = callable.expected_keys
        not_in_previous_keys = new_keys.reject { |key| previously_defined_keys.include?(key) }

        add_missing_keys(callable, not_in_previous_keys)
      end

      def add_missing_keys(callable, not_in_previous_keys)
        return if not_in_previous_keys.empty?

        missing_keys[callable] ||= Set.new
        missing_keys[callable] += not_in_previous_keys
      end
    end

    concerning :Constants do
      def organizers
        @organizers ||= organizer_files.flat_map do |f|
          next if f[/interactor_organizer_contracts/] || f[/interactor_contracts/]

          callables_in_file(f)
        end.compact.select(&:organizer?)
      end

      def interactors
        @interactors ||= interactor_files.flat_map do |f|
          callables_in_file(f)
        end.compact.reject(&:organizer?)
      end

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
        CallableRepresentation.new(filename: filename, klass: klass, wiring: wiring)
      end

      def interactor_lookup
        @interactor_lookup ||= (interactors + organizers).index_by(&:klass)
      end

      private

      def constant_for(filename)
        require filename

        underscored_klass_name = underscored_klass_name_without_outer_namespace(filename)
        underscored_klass_name = trim_rails_folder underscored_klass_name

        klass_name = underscored_klass_name.classify

        should_pluralize = filename[underscored_klass_name.pluralize]
        klass_name = klass_name.pluralize if should_pluralize

        outer_namespace_constant.const_get(klass_name)
      end

      # Example:
      # trim_rails_folder("interactors/namespace/sub_namespace/class_name.rb")
      # => "namespace/sub_namespace/class_name.rb"
      def trim_rails_folder(filename)
        rails_folders = Dir.glob(Interactify.root / '*').map { |f| File.basename(f) }

        rails_folders.each do |folder|
          regexable_folder = Regexp.quote("#{folder}/")
          regex = /^#{regexable_folder}/

          return filename.gsub(regex, '') if filename.match?(regex)
        end

        filename
      end

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

    concerning :Files do
      def organizer_files
        possible_files.select { |_, contents| organizer_file?(contents) }.map(&:first).sort
      end

      def interactor_files
        possible_files.select { |_, contents| interactor_file?(contents) }.map(&:first).sort
      end

      def organizer_file?(file_contents)
        (file_contents['include Interactify'] || file_contents[/include Interactor::Organizer/]) &&
          file_contents[/^\s+organize/]
      end

      def interactor_file?(file_contents)
        file_contents['include Interactify'] || file_contents[/include Interactor$/]
      end

      def possible_files
        @possible_files ||= Dir.glob("#{root}/**/*.rb").map { |f| [f, File.read(f)] }
      end
    end
  end
end

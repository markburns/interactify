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



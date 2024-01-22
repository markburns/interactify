module Interactify
  module Configure
    def validate_app(ignore: [])
      Interactify::Wiring.new(root: Interactify.configuration.root, ignore:).validate_app
    end

    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end
end

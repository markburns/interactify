module Interactify
  class NullJob
    def method_missing(...)
      self
    end

    def self.method_missing(...)
      self
    end
  end
end

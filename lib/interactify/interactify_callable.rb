# frozen_string_literal: true

require "interactify/dsl/wrapper"

# rubocop: disable Naming/MethodName
def Interactify(method_callable = nil, &block)
  to_wrap = method_callable || block

  Interactify::Dsl::Wrapper.wrap(self, to_wrap)
end
# rubocop: enable Naming/MethodName

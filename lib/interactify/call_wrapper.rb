module Interactify
  module CallWrapper
    # https://github.com/collectiveidea/interactor/blob/57b2af9a5a5afeb2c01059c40b792485cc21b052/lib/interactor.rb#L114
    # Interactor#run calls Interactor#run!
    # https://github.com/collectiveidea/interactor/blob/57b2af9a5a5afeb2c01059c40b792485cc21b052/lib/interactor.rb#L49
    # Interactor.call calls Interactor.run
    #
    # The non bang methods call the bang methods and rescue
    def run
      @_interactor_called_by_non_bang_method = true

      super
    end
  end
end

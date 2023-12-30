module Each
  class Organizer
    include Interactify
    expect :things

    organize \
      A, B, C, D,
      self.each(:things, A, B, C, D)
  end
end

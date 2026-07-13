module HandEvaluator
  class << self
    def call(hands)
      {
        one_pair: 1,
        two_pair: 2,
        thiree:   2,
        straight: 4,
        flush:    3,
        full_house: 3,
        four:       3,
        straight_flush: 4,
        royal_straight_flush: 5
      }
    end
  end
end

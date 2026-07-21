require_relative "hand_evaluator"

module RewardCalculator
  ROLE_WEIGHTS = {
    one_pair: 1,
    two_pair: 2,
    thiree: 3,
    straight: 4,
    flush: 5,
    full_house: 6,
    four: 7,
    straight_flush: 8,
    royal_straight_flush: 9
  }.freeze

  MAX_DISTANCES = {
    one_pair: 1,
    two_pair: 2,
    thiree: 2,
    straight: 4,
    flush: 3,
    full_house: 3,
    four: 3,
    straight_flush: 4,
    royal_straight_flush: 5
  }.freeze

  WEIGHT_SUM = ROLE_WEIGHTS.values.sum.to_f
  POTENTIAL_SCALE = 0.05

  FINAL_REWARDS = {
    one_pair: 0.3,
    two_pair: 0.4,
    thiree: 0.5,
    straight: 0.6,
    flush: 0.7,
    full_house: 0.8,
    four: 0.9,
    straight_flush: 0.95,
    royal_straight_flush: 1.0
  }.freeze

  class << self
    def calculate_final_reward(hands)
      validate_hand_size!(hands)
      hand_ranks = HandEvaluator.call(hands)

      return FINAL_REWARDS[:royal_straight_flush] if hand_ranks[:royal_straight_flush].zero?
      return FINAL_REWARDS[:straight_flush] if hand_ranks[:straight_flush].zero?
      return FINAL_REWARDS[:four] if hand_ranks[:four].zero?
      return FINAL_REWARDS[:full_house] if hand_ranks[:full_house].zero?
      return FINAL_REWARDS[:flush] if hand_ranks[:flush].zero?
      return FINAL_REWARDS[:straight] if hand_ranks[:straight].zero?
      return FINAL_REWARDS[:thiree] if hand_ranks[:thiree].zero?
      return FINAL_REWARDS[:two_pair] if hand_ranks[:two_pair].zero?
      return FINAL_REWARDS[:one_pair] if hand_ranks[:one_pair].zero?
      -0.2
    end

    def calculate_shaping_reward(before_hands, next_hands, gamma:)
      before_potential = calculate_potential(before_hands)
      next_potential = calculate_potential(next_hands)

      gamma * next_potential - before_potential
    end

    def calculate_terminal_shaping_reward(hands)
      -calculate_potential(hands)
    end

    private

    def validate_hand_size!(hands, expected_size: 5)
      return if hands.size == expected_size
      raise ArgumentError, "手札は#{expected_size}枚である必要があります: #{hands.size}枚です"
    end

    def calculate_potential(hands)
      validate_hand_size!(hands, expected_size: 6)

      hands.combination(5).map do |five_card_hands|
        calculate_five_card_potential(five_card_hands)
      end.max
    end

    def calculate_five_card_potential(hands)
      hand_ranks = HandEvaluator.call(hands)
      calculate_five_card_potential_from_hand_ranks(hand_ranks)
    end

    def calculate_five_card_potential_from_hand_ranks(hand_ranks)
      raw_potential = hand_ranks.sum do |name, distance|
        normalized_weight = ROLE_WEIGHTS.fetch(name) / WEIGHT_SUM
        proximity = 1.0 - distance.fdiv(MAX_DISTANCES.fetch(name))

        normalized_weight * proximity
      end

      raw_potential * POTENTIAL_SCALE
    end
  end
end

require_relative "game_constants"

module HandEvaluator
  ONE_PAIR_MAX_DISTANCE = 1
  THIREE_MAX_DISTANCE = 2
  FLUSH_NEED_COUNT = 5
  HAND_RANK_NEED_COUNT = 5
  STRAIGHT_COMBINATION_MAP = (1..9).map do |n|
    end_number = n + 4
    (n..end_number).to_a
  end.push([10, 11, 12, 13, 1]).freeze

  ROYAL_STRAIGHT_FLUSH_COMBINATION_MAP = [
    [101, 110, 111, 112, 113],
    [201, 210, 211, 212, 213],
    [301, 310, 311, 312, 313],
    [401, 410, 411, 412, 413]
  ].freeze

  class << self
    def call(hands)
      {
        one_pair: calculate_one_pair_distance(hands),
        two_pair: calculate_two_pair_distance(hands),
        thiree: calculate_thiree_distance(hands),
        straight: calculate_straight_distance(hands),
        flush: calculate_flush_distance(hands),
        full_house: calculate_full_house_distance(hands),
        four: calculate_four_distance(hands),
        straight_flush: calculate_straight_flush_distance(hands),
        royal_straight_flush: calculate_royal_straight_flush_distance(hands)
      }
    end

    private

    def calculate_one_pair_distance(hands)
      pair_count = count_pair(hands)
      [ONE_PAIR_MAX_DISTANCE - pair_count, 0].max
    end

    def calculate_two_pair_distance(hands)
      force_count = count_force(hands)
      triple_count = count_triple(hands)
      pair_count = count_pair(hands)

      if pair_count >= 2
        0
      elsif complete_full_house?(force_count, triple_count, pair_count) || triple_count == 1 || pair_count == 1
        1
      else
        2
      end
    end

    def calculate_thiree_distance(hands)
      triple_count = count_triple(hands)
      return 0 if triple_count >= 1

      force_count = count_force(hands)
      return 1 if force_count.positive?

      count_pair(hands).positive? ? 1 : THIREE_MAX_DISTANCE
    end

    def calculate_straight_distance(hands)
      straight_combnation_count = count_straight_combnation(hands)
      HAND_RANK_NEED_COUNT - straight_combnation_count.max
    end

    def calculate_flush_distance(hands)
      suits = hands.map { |card| card.to_s[0] }
      most_same_suit_count = occurrence_counts(suits).max || 0
      [FLUSH_NEED_COUNT - most_same_suit_count, 0].max
    end

    def calculate_full_house_distance(hands)
      force_count = count_force(hands)
      triple_count = count_triple(hands)
      pair_count = count_pair(hands)

      if complete_full_house?(force_count, triple_count, pair_count)
        0
      elsif force_count.positive? || (triple_count == 1 && pair_count.zero?) || (triple_count.zero? && pair_count >= 2)
        1
      elsif triple_count.zero? && pair_count == 1
        2
      else
        3
      end
    end

    def complete_full_house?(force_count, triple_count, pair_count)
      (force_count.positive? && pair_count.positive?) || triple_count == 2 || triple_count == 1 && pair_count == 1
    end

    def calculate_four_distance(hands)
      force_count = count_force(hands)
      return 0 if force_count.positive?

      triple_count = count_triple(hands)
      return 1 if triple_count.positive?

      pair_count = count_pair(hands)
      return 2 if pair_count.positive?

      3
    end

    def calculate_straight_flush_distance(hands)
      hearts = hands.select { |card| card.to_s[0].to_i == GameConstants::HEART_SUIT_NUMBER }
      diamonds = hands.select { |card| card.to_s[0].to_i == GameConstants::DIAMOND_SUIT_NUMBER }
      spades = hands.select { |card| card.to_s[0].to_i == GameConstants::SPADE_SUIT_NUMBER }
      clovers = hands.select { |card| card.to_s[0].to_i == GameConstants::CLOVER_SUIT_NUMBER }

      heart_straight_count = count_straight_combnation(hearts)
      diamond_straight_count = count_straight_combnation(diamonds)
      spades_straight_count = count_straight_combnation(spades)
      clover_straight_count = count_straight_combnation(clovers)

      straight_flush_count = [
        heart_straight_count.max,
        diamond_straight_count.max,
        spades_straight_count.max,
        clover_straight_count.max
      ].max
      HAND_RANK_NEED_COUNT - straight_flush_count
    end

    def calculate_royal_straight_flush_distance(hands)
      distance_map = Array.new(ROYAL_STRAIGHT_FLUSH_COMBINATION_MAP.size)

      ROYAL_STRAIGHT_FLUSH_COMBINATION_MAP.each_with_index do |comb, index|
        counter = 0
        hands.each do |card|
          counter += 1 if comb.include?(card)
        end
        distance_map[index] = counter
      end
      HAND_RANK_NEED_COUNT - distance_map.max
    end

    def count_straight_combnation(hands)
      uniq_numbers = hands.map { |card| card.to_s[1..].to_i }.uniq
      distance_map = Array.new(STRAIGHT_COMBINATION_MAP.size)

      STRAIGHT_COMBINATION_MAP.each_with_index do |comb, index|
        counter = 0
        uniq_numbers.each do |number|
          counter += 1 if comb.include?(number)
        end
        distance_map[index] = counter
      end
      distance_map
    end

    def count_pair(hands)
      numbers = hands.map { |card| card.to_s[1..] }
      occurrence_counts(numbers).count(2)
    end

    def count_triple(hands)
      numbers = hands.map { |card| card.to_s[1..] }
      occurrence_counts(numbers).count(3)
    end

    def count_force(hands)
      numbers = hands.map { |card| card.to_s[1..] }
      occurrence_counts(numbers).count(4)
    end

    def occurrence_counts(values)
      values.group_by(&:itself).map { |_, occurrences| occurrences.size }
    end
  end
end

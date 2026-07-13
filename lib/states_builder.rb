require_relative "game_constants"
require_relative "hand_evaluator"

module StatesBuilder
  class << self
    def call(hands, graveyards, decks, draw_count)
      hand_states = build_card_states(hands)
      graveyard_states = build_card_states(graveyards)
      hand_rank_states = build_hand_rank_states(hands)
      normalized_remaining_deck_count = build_normalized_remaining_deck_count(decks)
      normalized_remaining_round_count = build_normalized_remaining_round_count(draw_count)

      [
        *hand_states,
        *graveyard_states,
        *hand_rank_states,
        normalized_remaining_deck_count,
        normalized_remaining_round_count
      ]
    end

    private

    def build_card_states(cards)
      heart_card_states   = [0] * 13
      diamond_card_states = [0] * 13
      spade_card_states   = [0] * 13
      clover_card_states  = [0] * 13

      cards.each do |card|
        suit = card.to_s[0].to_i
        index = card.to_s[1..].to_i - 1

        case suit
        when GameConstants::HEART_SUIT_NUMBER   then heart_card_states[index] = 1
        when GameConstants::DIAMOND_SUIT_NUMBER then diamond_card_states[index] = 1
        when GameConstants::SPADE_SUIT_NUMBER   then spade_card_states[index] = 1
        when GameConstants::CLOVER_SUIT_NUMBER  then clover_card_states[index] = 1
        end
      end
      heart_card_states + diamond_card_states + spade_card_states + clover_card_states
    end

    def build_hand_rank_states(hands)
      hand_ranks = HandEvaluator.call(hands)
      hand_rank_states = build_initial_hand_rank_states

      hand_ranks.each do |name, distance|
        hand_rank_states[name][distance] = 1
      end
      hand_rank_states.map { |_, states| states.reverse }.flatten
    end

    def build_initial_hand_rank_states
      {
        one_pair:   [0] * 2,
        two_pair:   [0] * 3,
        thiree:     [0] * 3,
        straight:   [0] * 5,
        flush:      [0] * 4,
        full_house: [0] * 4,
        four:       [0] * 4,
        straight_flush: [0] * 5,
        royal_straight_flush: [0] * 6
      }
    end

    def build_normalized_remaining_deck_count(decks)
      remaining_deck_count = decks.size
      remaining_deck_count.fdiv(52)
    end

    def build_normalized_remaining_round_count(draw_count)
      remaining_round_count = GameConstants::FINAL_ROUND_NUMBER - draw_count
      remaining_round_count.fdiv(GameConstants::FINAL_ROUND_NUMBER)
    end
  end
end

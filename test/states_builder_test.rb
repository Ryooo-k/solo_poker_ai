# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/states_builder"

class StatesBuilderTest < Minitest::Test
  CARD_STATE_SIZE = 52
  GRAVEYARD_STATE_OFFSET = CARD_STATE_SIZE
  HAND_RANK_STATE_OFFSET = GRAVEYARD_STATE_OFFSET + CARD_STATE_SIZE
  HAND_RANK_STATE_SIZE = 36
  REMAINING_DECK_COUNT_STATE_OFFSET = HAND_RANK_STATE_OFFSET + HAND_RANK_STATE_SIZE
  REMAINING_ROUND_COUNT_STATE_OFFSET = REMAINING_DECK_COUNT_STATE_OFFSET + 1
  STATE_SIZE = 142
  HAND_RANKS = {
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

  def test_hand_card_states_follow_suit_and_rank_order
    hands = [101, 113, 205, 307, 412]

    states = build_states(hands: hands)

    expected = [0] * CARD_STATE_SIZE
    expected[0] = 1
    expected[12] = 1
    expected[13 + 4] = 1
    expected[26 + 6] = 1
    expected[39 + 11] = 1

    assert_equal expected, hand_card_states(states)
  end

  def test_hand_card_states_are_all_zero_when_hands_are_empty
    states = build_states

    assert_equal [0] * CARD_STATE_SIZE, hand_card_states(states)
  end

  def test_duplicate_cards_do_not_increase_hand_card_state_value
    states = build_states(hands: [101, 101])

    expected = [0] * CARD_STATE_SIZE
    expected[0] = 1

    assert_equal expected, hand_card_states(states)
  end

  def test_graveyard_card_states_follow_suit_and_rank_order
    graveyards = [102, 113, 206, 308, 413]

    states = build_states(graveyards: graveyards)

    expected = [0] * CARD_STATE_SIZE
    expected[1] = 1
    expected[12] = 1
    expected[13 + 5] = 1
    expected[26 + 7] = 1
    expected[39 + 12] = 1

    assert_equal expected, graveyard_card_states(states)
  end

  def test_hand_and_graveyard_card_states_are_independent
    states = build_states(hands: [101], graveyards: [213])

    expected_hands = [0] * CARD_STATE_SIZE
    expected_hands[0] = 1
    expected_graveyards = [0] * CARD_STATE_SIZE
    expected_graveyards[13 + 12] = 1

    assert_equal expected_hands, hand_card_states(states)
    assert_equal expected_graveyards, graveyard_card_states(states)
  end

  def test_hand_rank_states_follow_hand_evaluator_distances
    states = build_states(hand_ranks: HAND_RANKS)

    expected = [
      1, 0,
      1, 0, 0,
      1, 0, 0,
      1, 0, 0, 0, 0,
      1, 0, 0, 0,
      1, 0, 0, 0,
      1, 0, 0, 0,
      1, 0, 0, 0, 0,
      1, 0, 0, 0, 0, 0
    ]

    assert_equal expected, hand_rank_states(states)
  end

  def test_hand_rank_states_keep_unspecified_hand_ranks_at_zero
    states = build_states(hand_ranks: { one_pair: 0, straight: 3, royal_straight_flush: 0 })

    expected = [
      0, 1,
      0, 0, 0,
      0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 1
    ]

    assert_equal expected, hand_rank_states(states)
  end

  def test_states_have_expected_size
    assert_equal STATE_SIZE, build_states.size
  end

  def test_remaining_deck_count_is_normalized
    assert_in_delta 1.0, remaining_deck_count_state(build_states(decks: Array.new(52)))
    assert_in_delta 0.5, remaining_deck_count_state(build_states(decks: Array.new(26)))
    assert_in_delta 0.0, remaining_deck_count_state(build_states(decks: []))
  end

  def test_remaining_round_count_is_normalized
    expected_remaining_round_counts = [1.0, 0.8, 0.6, 0.4, 0.2, 0.0]

    expected_remaining_round_counts.each_with_index do |expected, draw_count|
      actual = remaining_round_count_state(build_states(draw_count: draw_count))

      assert_in_delta expected, actual
    end
  end

  private

  def build_states(hands: [], graveyards: [], decks: [], draw_count: 0, hand_ranks: HAND_RANKS)
    HandEvaluator.stub(:call, hand_ranks) do
      StatesBuilder.call(hands, graveyards, decks, draw_count)
    end
  end

  def hand_card_states(states)
    states.first(CARD_STATE_SIZE)
  end

  def graveyard_card_states(states)
    states[GRAVEYARD_STATE_OFFSET, CARD_STATE_SIZE]
  end

  def hand_rank_states(states)
    states[HAND_RANK_STATE_OFFSET, HAND_RANK_STATE_SIZE]
  end

  def remaining_deck_count_state(states)
    states[REMAINING_DECK_COUNT_STATE_OFFSET]
  end

  def remaining_round_count_state(states)
    states[REMAINING_ROUND_COUNT_STATE_OFFSET]
  end
end

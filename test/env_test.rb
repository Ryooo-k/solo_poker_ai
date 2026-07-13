# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/env"

class FixedActionAgent
  def initialize(action)
    @action = action
  end

  def get_action(_states)
    @action
  end
end

class EnvTest < Minitest::Test
  FULL_DECK = ((101..113).to_a + (201..213).to_a + (301..313).to_a + (401..413).to_a).freeze

  def setup
    @env = Env.new
  end

  def test_reset_starts_new_episode
    @env.reset

    assert_equal 6, hands.size
    assert_equal 46, decks.size
    assert_equal [], graveyards
    assert_equal 1, draw_count
    refute done
    assert_equal FULL_DECK.sort, (hands + decks + graveyards).sort
  end

  def test_step_discards_agent_action_and_draws_next_card
    @env = Env.new(agent: FixedActionAgent.new(2))
    @env.reset

    before_hands = hands.dup
    before_decks = decks.dup
    discarded_card = before_hands[2]
    expected_old_hands = before_hands.dup
    expected_old_hands.delete_at(2)

    states, action, reward, next_states, episode_done = @env.step

    assert_equal 142, states.size
    assert_equal 2, action
    assert_equal 0, reward
    assert_equal 142, next_states.size
    refute episode_done

    assert_equal expected_old_hands + [before_decks.first], hands
    assert_equal [discarded_card], graveyards
    assert_equal before_decks.drop(1), decks
    assert_equal 2, draw_count
    assert_equal expected_old_hands, old_hands
  end

  def test_step_finishes_on_final_round_without_extra_draw
    @env = Env.new(agent: FixedActionAgent.new(0))
    @env.reset

    results = Env::FINAL_ROUND_NUMBER.times.map { @env.step }

    refute results[0].last
    assert results.last.last
    assert_equal Env::FINAL_ROUND_NUMBER, graveyards.size
    assert_equal 5, hands.size
    assert_equal 5, draw_count
    assert_equal 42, decks.size
    assert_equal FULL_DECK.sort, (hands + decks + graveyards).sort
  end

  private

  def hands
    @env.instance_variable_get(:@hands)
  end

  def decks
    @env.instance_variable_get(:@decks)
  end

  def graveyards
    @env.instance_variable_get(:@graveyards)
  end

  def draw_count
    @env.instance_variable_get(:@draw_count)
  end

  def done
    @env.instance_variable_get(:@done)
  end

  def old_hands
    @env.instance_variable_get(:@old_hands)
  end
end

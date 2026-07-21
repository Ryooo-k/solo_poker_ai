# frozen_string_literal: true

require "minitest/autorun"
require "minitest/mock"
require "minitest/spec"
require_relative "../lib/env"

class FixedActionAgent
  attr_reader :gamma

  def initialize(action, gamma:)
    @action = action
    @gamma = gamma
  end

  def get_action(_states)
    @action
  end
end

describe Env do
  FULL_DECK = ((101..113).to_a + (201..213).to_a + (301..313).to_a + (401..413).to_a).freeze
  GAMMA = 0.99

  before do
    @env = Env.new(agent: FixedActionAgent.new(0, gamma: GAMMA))
  end

  it "リセットで新しいエピソードを開始する" do
    @env.reset

    assert_equal 6, hands.size
    assert_equal 46, decks.size
    assert_equal [], graveyards
    assert_equal 1, draw_count
    refute done
    assert_equal FULL_DECK.sort, (hands + decks + graveyards).sort
  end

  it "ステップで行動対象を捨てて次のカードを引く" do
    @env = Env.new(agent: FixedActionAgent.new(2, gamma: GAMMA))
    @env.reset

    before_hands = hands.dup
    before_decks = decks.dup
    discarded_card = before_hands[2]
    expected_hands_after_discard = before_hands.dup
    expected_hands_after_discard.delete_at(2)

    states, action, reward, next_states, episode_done = @env.step

    assert_equal 142, states.size
    assert_equal 2, action
    assert_instance_of Float, reward
    assert_in_delta 0.0, reward, 0.05
    assert_equal 142, next_states.size
    refute episode_done

    assert_equal expected_hands_after_discard + [before_decks.first], hands
    assert_equal [discarded_card], graveyards
    assert_equal before_decks.drop(1), decks
    assert_equal 2, draw_count
  end

  it "最終ラウンドで追加ドローせず終了する" do
    @env = Env.new(agent: FixedActionAgent.new(0, gamma: GAMMA))
    @env.reset

    results = Env::FINAL_ROUND_NUMBER.times.map { @env.step }
    first_done = results.first.last
    final_done = results.last.last

    refute first_done
    assert final_done
    assert_equal Env::FINAL_ROUND_NUMBER, graveyards.size
    assert_equal 5, hands.size
    assert_equal 5, draw_count
    assert_equal 42, decks.size
    assert_equal FULL_DECK.sort, (hands + decks + graveyards).sort
  end

  it "最終ラウンドで終端報酬を返す" do
    @env.reset
    terminal_reward = 1.0
    terminal_shaping_reward = -0.05
    shaping_reward_calls = 0
    shaping_reward_gammas = []
    shaping_hand_sizes = []
    final_reward_calls = 0
    final_reward_hand_sizes = []
    terminal_shaping_reward_calls = 0
    terminal_shaping_hand_sizes = []

    RewardCalculator.stub(:calculate_shaping_reward, lambda { |current_hands, next_hands, gamma:|
      shaping_reward_calls += 1
      shaping_reward_gammas << gamma
      shaping_hand_sizes << [current_hands.size, next_hands.size]
      0.0
    }) do
      RewardCalculator.stub(:calculate_final_reward, lambda { |hands|
        final_reward_calls += 1
        final_reward_hand_sizes << hands.size
        terminal_reward
      }) do
        RewardCalculator.stub(:calculate_terminal_shaping_reward, lambda { |hands|
          terminal_shaping_reward_calls += 1
          terminal_shaping_hand_sizes << hands.size
          terminal_shaping_reward
        }) do
          results = Env::FINAL_ROUND_NUMBER.times.map { @env.step }
          final_reward = results.last[2]

          assert_equal terminal_reward + terminal_shaping_reward, final_reward
        end
      end
    end

    assert_equal Env::FINAL_ROUND_NUMBER - 1, shaping_reward_calls
    assert_equal Array.new(Env::FINAL_ROUND_NUMBER - 1, GAMMA), shaping_reward_gammas
    assert_equal Array.new(Env::FINAL_ROUND_NUMBER - 1, [6, 6]), shaping_hand_sizes
    assert_equal 1, final_reward_calls
    assert_equal [5], final_reward_hand_sizes
    assert_equal 1, terminal_shaping_reward_calls
    assert_equal [6], terminal_shaping_hand_sizes
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

end

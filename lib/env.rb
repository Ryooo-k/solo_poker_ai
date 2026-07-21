require_relative "agent"
require_relative "states_builder"
require_relative "reward_calculator"
require_relative "game_constants"

class Env
  FINAL_ROUND_NUMBER = GameConstants::FINAL_ROUND_NUMBER

  def initialize(agent:)
    @agent = agent
    @gamma = agent.gamma
  end

  def reset
    @decks = build_decks
    @hands = []
    @graveyards = []
    @draw_count = 0
    @done = false

    5.times { |_| @hands << @decks.shift }
    draw
  end

  def step
    return if @done

    before_hands = @hands.dup
    states = StatesBuilder.call(before_hands, @graveyards, @decks, @draw_count)
    action = @agent.get_action(states)
    discard(action)

    if game_end?
      @done = true
      reward = RewardCalculator.calculate_final_reward(@hands)
      reward += RewardCalculator.calculate_terminal_shaping_reward(before_hands)
    else
      draw
      reward = RewardCalculator.calculate_shaping_reward(before_hands, @hands, gamma: @gamma)
    end

    next_states = StatesBuilder.call(@hands, @graveyards, @decks, @draw_count)
    [states, action, reward, next_states, @done]
  end

  private

  def build_decks
    h_cards = (101..113).to_a
    d_cards = (201..213).to_a
    s_cards = (301..313).to_a
    c_cares = (401..413).to_a
    (h_cards + d_cards + s_cards + c_cares).shuffle
  end

  def draw
    @hands << @decks.shift
    @draw_count += 1
  end

  def discard(index)
    discarded_card = @hands.delete_at(index.to_i)
    @graveyards << discarded_card
  end

  def game_end?
    @draw_count >= FINAL_ROUND_NUMBER
  end
end

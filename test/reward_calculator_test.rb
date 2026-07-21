# frozen_string_literal: true

require "minitest/autorun"
require "minitest/mock"
require "minitest/spec"
require_relative "../lib/reward_calculator"

describe RewardCalculator do
  describe "ポテンシャル" do
    it "6枚の手札から最も高いポテンシャルを持つ5枚を選ぶ" do
      hands = [101, 202, 303, 404, 105, 206]
      next_hands = [107, 208, 309, 410, 111, 212]
      best_five_card_hands = [101, 202, 303, 404, 105]
      minimum_potential_hand_ranks = RewardCalculator::MAX_DISTANCES
      # テスト用に全役の距離を0とする。実際の手札には対応しない評価結果。
      simulated_maximum_potential_hand_ranks = minimum_potential_hand_ranks.transform_values { 0 }

      HandEvaluator.stub(:call, lambda { |five_card_hands|
        five_card_hands == best_five_card_hands ? simulated_maximum_potential_hand_ranks : minimum_potential_hand_ranks
      }) do
        reward = RewardCalculator.calculate_shaping_reward(hands, next_hands, gamma: 0.99)

        assert_in_delta(-0.05, reward, 1e-10)
      end
    end

    it "6枚ではない手札を受け取るとエラーにする" do
      error = assert_raises(ArgumentError) do
        RewardCalculator.calculate_shaping_reward(
          [101, 202, 303, 404, 105],
          [101, 202, 303, 404, 105, 206],
          gamma: 0.99
        )
      end

      assert_equal "手札は6枚である必要があります: 5枚です", error.message
    end
  end

  describe "シェイピング報酬" do
    it "gammaで割り引いた次状態のポテンシャルとの差分を返す" do
      current_hands = Array.new(6, :current_card)
      next_hands = Array.new(6, :next_card)
      potentials = { current_hands => 0.01, next_hands => 0.04 }

      RewardCalculator.stub(:calculate_potential, ->(hands) { potentials.fetch(hands) }) do
        reward = RewardCalculator.calculate_shaping_reward(current_hands, next_hands, gamma: 0.99)

        assert_in_delta 0.0296, reward, 1e-10
      end
    end

    it "終端時は現在のポテンシャルを差し引く" do
      hands = Array.new(6, :current_card)

      RewardCalculator.stub(:calculate_potential, ->(_hands) { 0.03 }) do
        assert_in_delta(-0.03, RewardCalculator.calculate_terminal_shaping_reward(hands), 1e-10)
      end
    end
  end

  describe "最終報酬" do
    it "終端報酬を-0.2から1.0の範囲に正規化する" do
      assert_equal 0.3, RewardCalculator::FINAL_REWARDS[:one_pair]
      assert_equal 1.0, RewardCalculator::FINAL_REWARDS[:royal_straight_flush]
      assert_equal(-0.2, RewardCalculator.calculate_final_reward([101, 202, 304, 406, 108]))
    end

    it "最強役に対応する報酬を返す" do
      RewardCalculator::FINAL_REWARDS.each do |role, expected_reward|
        hand_ranks = RewardCalculator::MAX_DISTANCES.merge(role => 0)

        assert_equal expected_reward, reward_for(hand_ranks)
      end
    end

    it "各役の実際の手札に対応する報酬を返す" do
      final_hands = {
        one_pair: [101, 201, 303, 404, 105],
        two_pair: [101, 201, 303, 403, 105],
        thiree: [101, 201, 301, 404, 105],
        straight: [101, 202, 303, 404, 105],
        flush: [101, 103, 105, 107, 109],
        full_house: [101, 201, 301, 403, 103],
        four: [101, 201, 301, 401, 105],
        straight_flush: [101, 102, 103, 104, 105],
        royal_straight_flush: [101, 110, 111, 112, 113]
      }

      final_hands.each do |role, hands|
        assert_equal RewardCalculator::FINAL_REWARDS.fetch(role), RewardCalculator.calculate_final_reward(hands)
      end
    end

    it "複数の役が完成している場合は最強役を選ぶ" do
      hand_ranks = RewardCalculator::MAX_DISTANCES.merge(one_pair: 0, two_pair: 0, thiree: 0)

      assert_equal RewardCalculator::FINAL_REWARDS[:thiree], reward_for(hand_ranks)
    end

    it "ブタの場合は-0.2を返す" do
      assert_equal(-0.2, reward_for(RewardCalculator::MAX_DISTANCES))
    end
  end

  private

  def reward_for(current_hand_ranks)
    current_hand_placeholder = Array.new(5, :current_card)
    hand_ranks_by_hand = {
      current_hand_placeholder => current_hand_ranks
    }

    HandEvaluator.stub(:call, ->(hands) { hand_ranks_by_hand.fetch(hands) }) do
      RewardCalculator.calculate_final_reward(current_hand_placeholder)
    end
  end
end

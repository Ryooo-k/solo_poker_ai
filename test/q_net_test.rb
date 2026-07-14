# frozen_string_literal: true

require "minitest/autorun"
require "minitest/spec"
require_relative "../lib/q_net"

describe QNet do
  it "状態ベクトルから行動ごとのQ値を出力する" do
    input_size = 142
    hidden_sizes = [256, 128, 64]
    action_size = 6
    batch_size = 4
    q_net = QNet.new(input_size:, hidden_sizes:, action_size:)

    state = Torch.zeros(input_size)
    batch_states = Torch.zeros(batch_size, input_size)

    assert_equal [action_size], q_net.call(state).shape
    assert_equal [batch_size, action_size], q_net.call(batch_states).shape
  end

  it "入力数、隠れ層、行動数を変更できる" do
    q_net = QNet.new(input_size: 10, hidden_sizes: [8, 4], action_size: 3)

    assert_equal [2, 3], q_net.call(Torch.zeros(2, 10)).shape
  end

  it "全てのLinear層を学習対象として登録する" do
    q_net = QNet.new(input_size: 142, hidden_sizes: [256, 128, 64], action_size: 6)

    assert_equal 8, q_net.parameters.size
    assert_equal 4, q_net.modules.count { |mod| mod.is_a?(Torch::NN::Linear) }
    assert_equal 3, q_net.modules.count { |mod| mod.is_a?(Torch::NN::ReLU) }
    assert_instance_of Torch::NN::Linear, q_net.modules.last
  end

  it "層のサイズに正でない整数を指定できない" do
    assert_raises(ArgumentError) { QNet.new(input_size: 0, hidden_sizes: [256, 128, 64], action_size: 6) }
    assert_raises(ArgumentError) { QNet.new(input_size: 142, hidden_sizes: [64, -1], action_size: 6) }
    assert_raises(ArgumentError) { QNet.new(input_size: 142, hidden_sizes: [256, 128, 64], action_size: 0) }
  end

  it "層のサイズに整数以外を指定できない" do
    assert_raises(ArgumentError) { QNet.new(input_size: 142.0, hidden_sizes: [256, 128, 64], action_size: 6) }
  end
end

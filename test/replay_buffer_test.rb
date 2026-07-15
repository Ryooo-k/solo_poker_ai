# frozen_string_literal: true

require "minitest/autorun"
require "minitest/spec"
require_relative "../lib/replay_buffer"

describe ReplayBuffer do
  it "状態をfloat32のスナップショットとして保存する" do
    buffer = ReplayBuffer.new(2, 1)
    state = Torch.tensor([1, 2], dtype: :long)

    buffer.add(state, 0, 0.5, state, false)
    state[0] = 99

    stored_state = buffer.buffers.first[:state]
    assert_equal :float32, stored_state.dtype
    assert_equal [1.0, 2.0], stored_state.to_a
    refute stored_state.requires_grad?
  end

  it "容量を超えると最も古い遷移を破棄する" do
    buffer = ReplayBuffer.new(2, 1)

    3.times do |index|
      buffer.add([index], index, index.to_f, [index + 1], false)
    end

    assert_equal 2, buffer.buffers.size
    assert_equal [[1.0], [2.0]], buffer.buffers.map { |transition| transition[:state].to_a }
  end

  it "期待する形状と型のバッチを返す" do
    buffer = ReplayBuffer.new(3, 2)
    buffer.add([1.0, 2.0], 0, 0.25, [3.0, 4.0], false)
    buffer.add([5.0, 6.0], 1, 1.5, [7.0, 8.0], true)

    states, actions, rewards, next_states, dones = buffer.get_batch

    assert_equal [2, 2], states.shape
    assert_equal [2, 2], next_states.shape
    assert_equal :float32, states.dtype
    assert_equal :int64, actions.dtype
    assert_equal :float32, rewards.dtype
    assert_equal :float32, dones.dtype
    assert_equal [0, 1], actions.to_a.sort
    assert_equal [0.25, 1.5], rewards.to_a.sort
    assert_equal [0.0, 1.0], dones.to_a.sort
  end
end

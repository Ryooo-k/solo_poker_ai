# frozen_string_literal: true

require 'torch'

class ReplayBuffer
  attr_reader :buffers

  def initialize(max_buffer_size, batch_size)
    @buffers = []
    @max_buffer_size = max_buffer_size
    @batch_size = batch_size
  end

  def add(state, action, reward, next_state, done)
    @buffers.shift if @buffers.size >= @max_buffer_size
    @buffers << {
      state: to_state_tensor(state),
      action:,
      reward:,
      next_state: to_state_tensor(next_state),
      done:
    }
  end

  def get_batch
    data = @buffers.sample(@batch_size)
    states = data.map { |d| d[:state] }
    actions = data.map { |d| d[:action] }
    rewards = data.map { |d| d[:reward] }
    next_states = data.map { |d| d[:next_state] }
    dones = data.map { |d| d[:done] ? 1.0 : 0.0 }

    [
      Torch.stack(states),
      Torch.tensor(actions, dtype: :long),
      Torch.tensor(rewards, dtype: :float32),
      Torch.stack(next_states),
      Torch.tensor(dones, dtype: :float32)
    ]
  end

  private

  def to_state_tensor(state)
    tensor = state.is_a?(Torch::Tensor) ? state : Torch.tensor(state)
    tensor.detach.to("cpu", dtype: :float32).clone
  end
end

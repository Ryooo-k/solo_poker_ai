# frozen_string_literal: true

require_relative "q_net"
require_relative "replay_buffer"

class Agent
  def initialize(parameters)
    @gamma = parameters[:gamma]
    @lr = parameters[:lr]
    @epsilon = parameters[:epsilon]
    @action_size = parameters[:action_size]
    @batch_size = parameters[:batch_size]
    @device = Torch.device(Torch::Backends::MPS.available? ? "mps" : "cpu")
    @q_net = QNet.new(
      input_size: parameters[:input_size],
      hidden_sizes: parameters[:hidden_sizes],
      action_size: @action_size
    ).to(@device)

    @q_net_target = QNet.new(
      input_size: parameters[:input_size],
      hidden_sizes: parameters[:hidden_sizes],
      action_size: @action_size
    ).to(@device)

    @replay_buffer = ReplayBuffer.new(parameters[:max_buffer_size], @batch_size)
    sync_qnet
    @optimizer = Torch::Optim::Adam.new(@q_net.parameters, lr: @lr)
    @criterion = Torch::NN::MSELoss.new
  end

  def get_action(state)
    if rand < @epsilon
      rand(@action_size)
    else
      state_tensor = Torch.tensor(state, dtype: :float32).unsqueeze(0)
      state_gpu = state_tensor.to(@device)
      qs = Torch.no_grad { @q_net.call(state_gpu) }
      qs.argmax.item
    end
  end

  def update(state, action, reward, next_state, done)
    @replay_buffer.add(state, action, reward, next_state, done)
    return nil if @replay_buffer.buffers.size < @batch_size

    states, actions, rewards, next_states, dones = @replay_buffer.get_batch
    states = states.to(@device, dtype: :float32)
    actions = actions.to(@device, dtype: :long)
    rewards = rewards.to(@device, dtype: :float32)
    next_states = next_states.to(@device, dtype: :float32)
    dones = dones.to(@device, dtype: :float32)
    indices = Torch.arange(@batch_size, dtype: :long).to(@device)

    all_qs = @q_net.call(states)
    action_qs = all_qs[indices, actions]
    next_qs = Torch.no_grad { @q_net_target.call(next_states).max(1)[0] }
    targets = rewards + (1 - dones) * @gamma * next_qs
    loss = @criterion.call(action_qs, targets)

    @optimizer.zero_grad
    loss.backward
    @optimizer.step
    loss.item
  end

  def sync_qnet
    @q_net_target.load_state_dict(@q_net.state_dict)
  end
end

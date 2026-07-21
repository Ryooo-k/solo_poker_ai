# frozen_string_literal: true

require "minitest/autorun"
require "minitest/spec"
require_relative "../lib/agent"

describe Agent do
  it "初期化時にgammaを設定する" do
    agent = Agent.new(parameters(gamma: 0.95))

    assert_equal 0.95, agent.gamma
  end

  it "初期化時にQネットワークとtargetネットワークを同期する" do
    agent = Agent.new(parameters)

    assert_networks_equal(agent)
  end

  it "epsilonが1のとき行動範囲内でランダムに探索する" do
    agent = Agent.new(parameters(epsilon: 1.0))
    state = Array.new(142, 0.0)

    10.times do
      assert_includes 0...6, agent.get_action(state)
    end
  end

  it "epsilonが0のとき最大のQ値に対応する行動を選ぶ" do
    agent = Agent.new(parameters)
    state = Array.new(142, 0.5)
    q_net = agent.instance_variable_get(:@q_net)
    device = agent.instance_variable_get(:@device)
    state_tensor = Torch.tensor(state, dtype: :float32).unsqueeze(0).to(device)
    expected_action = q_net.call(state_tensor).argmax.item

    assert_equal expected_action, agent.get_action(state)
  end

  it "バッチが揃うとQネットワークを更新する" do
    agent = Agent.new(parameters)
    state = Array.new(142, 0.5)
    next_state = Array.new(142, 0.25)
    q_net = agent.instance_variable_get(:@q_net)
    before = q_net.parameters.last.detach.cpu.clone

    assert_nil agent.update(state, 0, 1.0, next_state, false)
    assert_equal before.to_a, q_net.parameters.last.detach.cpu.to_a

    loss = agent.update(state, 1, 0.5, next_state, true)
    after = q_net.parameters.last.detach.cpu

    assert_instance_of Float, loss
    refute_equal before.to_a, after.to_a
  end

  it "終了状態では将来のQ値をTDターゲットに加えない" do
    agent = Agent.new(parameters(batch_size: 1, max_buffer_size: 1, lr: 0.0))
    q_net = agent.instance_variable_get(:@q_net)
    q_net_target = agent.instance_variable_get(:@q_net_target)

    Torch.no_grad do
      q_net.parameters.each(&:zero!)
      q_net_target.parameters.each(&:zero!)
      q_net_target.parameters.last.fill!(10.0)
    end

    loss = agent.update(Array.new(142, 0.0), 0, 1.0, Array.new(142, 0.0), true)

    assert_in_delta 1.0, loss, 1e-5
  end

  it "sync_qnetでtargetネットワークを同期する" do
    agent = Agent.new(parameters)
    q_net = agent.instance_variable_get(:@q_net)

    Torch.no_grad { q_net.parameters.last.fill!(42.0) }
    refute_equal q_net.parameters.last.cpu.to_a, agent.instance_variable_get(:@q_net_target).parameters.last.cpu.to_a

    agent.sync_qnet

    assert_networks_equal(agent)
  end

  private

  def parameters(**overrides)
    {
      gamma: 0.99,
      lr: 0.01,
      epsilon: 0.0,
      input_size: 142,
      hidden_sizes: [8, 4],
      action_size: 6,
      batch_size: 2,
      max_buffer_size: 3
    }.merge(overrides)
  end

  def assert_networks_equal(agent)
    q_net = agent.instance_variable_get(:@q_net)
    q_net_target = agent.instance_variable_get(:@q_net_target)

    q_net.parameters.zip(q_net_target.parameters) do |parameter, target_parameter|
      assert_equal parameter.detach.cpu.to_a, target_parameter.detach.cpu.to_a
    end
  end
end

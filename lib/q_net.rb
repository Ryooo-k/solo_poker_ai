# frozen_string_literal: true

require "torch"

class QNet < Torch::NN::Module
  def initialize(input_size:, action_size:, hidden_sizes:)
    super()

    layer_sizes = [input_size, *hidden_sizes, action_size]
    validate_layer_sizes!(layer_sizes)

    @network = Torch::NN::Sequential.new(*build_layers(layer_sizes))
  end

  def forward(x)
    @network.call(x)
  end

  private

  def build_layers(layer_sizes)
    layers = []

    layer_sizes.each_cons(2).with_index do |(in_size, out_size), index|
      layers << Torch::NN::Linear.new(in_size, out_size)
      layers << Torch::NN::ReLU.new unless index == layer_sizes.size - 2
    end

    layers
  end

  def validate_layer_sizes!(layer_sizes)
    return if layer_sizes.all? { |size| size.is_a?(Integer) && size.positive? }

    raise ArgumentError, "layer sizes must be positive integers"
  end
end

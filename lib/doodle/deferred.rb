class Doodle
  # save a block for later execution
  class DeferredBlock
    attr_accessor :block
    def initialize(arg_block = nil, &block)
      arg_block = block if block_given?
      @block = arg_block
    end
    def call(*a, &b)
      block.call(*a, &b)
    end
  end
end

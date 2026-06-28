# frozen_string_literal: true

# Class-level DSL for registering `before_execute` / `after_execute` /
# `around_execute` hooks on `Assistant::Service` subclasses (M-S1).
#
# Mixed into `Service.singleton_class` so the DSL is available at class
# definition time. Hooks are stored as `UnboundMethod`s on private
# anonymous Modules so we can bind `self` to the service instance and
# still pass a block (the continuation) into `around_execute` hooks.
#
# Hooks are inherited at subclass-definition time: a subclass receives
# a duplicate of each registered hook array. Adding more hooks to the
# subclass does not affect the parent, and vice-versa.
#
# See docs/v1/index.md M-S1 and docs/v1/index.md.
module Assistant::ExecuteCallbacks
  # The exhaustive set of hook types this module manages.
  # @return [Array<Symbol>]
  HOOK_TYPES = %i[before_execute after_execute around_execute].freeze

  # @return [Array<UnboundMethod>] hooks registered via {#before_execute}, in declaration order
  def before_execute_hooks
    @before_execute_hooks ||= []
  end

  # @return [Array<UnboundMethod>] hooks registered via {#after_execute}, in declaration order
  def after_execute_hooks
    @after_execute_hooks ||= []
  end

  # @return [Array<UnboundMethod>] hooks registered via {#around_execute}, in declaration order
  def around_execute_hooks
    @around_execute_hooks ||= []
  end

  # Register a block to run after validation and before `#execute`.
  # `self` inside the block is the service instance.
  #
  # @yield runs in the context of the service instance after validation, before `#execute`
  # @raise [ArgumentError] when no block is given
  # @return [Array<UnboundMethod>] the updated {#before_execute_hooks} chain
  def before_execute(&block)
    raise ArgumentError, 'before_execute requires a block' unless block

    before_execute_hooks << build_hook(block)
  end

  # Register a block to run after `#execute` returns. `self` inside the
  # block is the service instance; the execute result is passed as the
  # single positional argument.
  #
  # @yieldparam execute_result [Object] return value of `#execute`
  # @raise [ArgumentError] when no block is given
  # @return [Array<UnboundMethod>] the updated {#after_execute_hooks} chain
  def after_execute(&block)
    raise ArgumentError, 'after_execute requires a block' unless block

    after_execute_hooks << build_hook(block)
  end

  # Register a block that wraps `#execute`. `self` inside the block is
  # the service instance; the `&blk` block argument yields to the
  # inner stack (the next around hook, or `#execute` for the innermost
  # layer). Declaration order wraps: the first declared hook is the
  # outermost layer.
  #
  # @yield runs in the context of the service instance, wrapping the inner stack
  # @yieldparam blk [Proc] the continuation; call `yield` (or `blk.call`) to invoke the inner layer
  # @raise [ArgumentError] when no block is given
  # @return [Array<UnboundMethod>] the updated {#around_execute_hooks} chain
  def around_execute(&block)
    raise ArgumentError, 'around_execute requires a block' unless block

    around_execute_hooks << build_hook(block)
  end

  # Snapshot parent hooks into the subclass at definition time. The
  # snapshot is a `dup` so the subclass owns its own array and further
  # additions on either side never bleed across the hierarchy.
  #
  # @param subclass [Class] freshly defined subclass
  # @return [void]
  def inherited(subclass)
    super
    subclass.instance_variable_set(:@before_execute_hooks, before_execute_hooks.dup)
    subclass.instance_variable_set(:@after_execute_hooks,  after_execute_hooks.dup)
    subclass.instance_variable_set(:@around_execute_hooks, around_execute_hooks.dup)
  end

  private

  # Wrap the user's block in an anonymous Module so we can convert it
  # to an `UnboundMethod`. `um.bind_call(service, *args, &cont)` then
  # runs the user's block with `self` == the service instance AND
  # passes a block argument through to the block's `&blk` parameter,
  # which is essential for `around_execute` continuations and cannot
  # be expressed with `instance_exec` alone.
  def build_hook(block)
    mod = Module.new
    mod.send(:define_method, :__assistant_execute_hook__, &block)
    mod.instance_method(:__assistant_execute_hook__)
  end
end

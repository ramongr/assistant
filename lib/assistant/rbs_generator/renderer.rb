# frozen_string_literal: true

# Converts a Service subclass to a `.rbs` source string. Pure
# function; does no I/O.
module Assistant::RbsGenerator::Renderer
  class << self
    # Render a `.rbs` source string for the given `Service` subclass.
    # Module-prefix segments of the class name are wrapped in nested
    # `module ... end` blocks; the trailing segment becomes the
    # `class X < Assistant::Service` declaration. The body lists one
    # `def name: () -> Type` and `def name?: () -> bool` per declared
    # input.
    #
    # @param service_class [Class<Assistant::Service>]
    # @return [String] the rendered `.rbs` source, ending with a newline
    # @raise [RuntimeError] when `service_class` is anonymous or declares
    #   an input with a non-Class / anonymous `type:`
    def render(service_class)
      name = service_class.name or raise 'anonymous Service class cannot be rendered'
      segments = name.split('::')
      # `String#split` on a non-empty string always returns at least
      # one element, but Steep can't prove that -- guard for narrowing.
      class_name = segments.pop or raise "unexpected empty name for #{service_class.inspect}"
      body_lines = render_class_body(class_name, service_class.input_definitions)
      nested_lines = nest_in_modules(segments, body_lines)
      "#{[Assistant::RbsGenerator::MARKER, '', *nested_lines].join("\n")}\n"
    end

    private

    def render_class_body(class_name, definitions)
      header = "class #{class_name} < Assistant::Service"
      method_lines = definitions.flat_map { |name, options| input_method_lines(name, options) }
      return [header, 'end'] if method_lines.empty?

      [header, '', *method_lines.map { |line| "  #{line}" }, '', 'end']
    end

    def nest_in_modules(segments, body_lines)
      segments.reverse.reduce(body_lines) do |body, segment|
        indented = body.map { |line| line.empty? ? '' : "  #{line}" }
        ["module #{segment}", *indented, 'end']
      end
    end

    def input_method_lines(name, options)
      [
        "def #{name}: () -> #{render_type(name, options)}",
        "def #{name}?: () -> bool"
      ]
    end

    def render_type(name, options)
      raise "input #{name.inspect} has no `type:` declared" unless options.key?(:type)

      rendered = Array(options[:type]).map { |type| render_single_type(name, type) }
      union = rendered.length == 1 ? rendered.first : "(#{rendered.join(' | ')})"
      options[:allow_nil] == true ? "#{union}?" : union
    end

    def render_single_type(name, type)
      raise "input #{name.inspect} has non-Class type #{type.inspect}" unless type.is_a?(Module)

      type.name || raise("input #{name.inspect} has anonymous type")
    end
  end
end

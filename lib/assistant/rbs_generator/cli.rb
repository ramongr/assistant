# frozen_string_literal: true

require 'optparse'

module Assistant::RbsGenerator
  # Command-line entry point. Parses argv, loads the input files,
  # discovers Service subclasses, renders, writes.
  class Cli
    USAGE = <<~USAGE
      Usage: assistant-rbs [PATH...] [--output DIR] [--quiet]

      Loads every Ruby file under the given PATHs (default: lib/) and
      writes one .rbs file per Assistant::Service subclass found, under
      DIR (default: sig/).

      Existing .rbs files without the generator marker comment on their
      first line are left untouched.
    USAGE

    class << self
      def run(argv, stdout: $stdout, stderr: $stderr)
        new(argv, stdout:, stderr:).run
      end
    end

    def initialize(argv, stdout: $stdout, stderr: $stderr)
      @argv = argv
      @stdout = stdout
      @stderr = stderr
      @output_dir = Assistant::RbsGenerator::DEFAULT_OUTPUT_DIR
      @quiet = false
      @paths = nil
    end

    # Returns an exit status (0 on success, non-zero on failure).
    def run
      parse_options!
      before = service_subclasses
      load_paths(@paths || Assistant::RbsGenerator::DEFAULT_INPUT_PATHS)
      emit(service_subclasses - before)
      0
    rescue SystemExit => e
      e.status
    end

    private

    def emit(services)
      writer = Assistant::RbsGenerator::Writer.new(
        output_dir: @output_dir, quiet: @quiet, stdout: @stdout, stderr: @stderr
      )
      services.sort_by(&:name).each do |service_class|
        writer.write(service_class, Assistant::RbsGenerator::Renderer.render(service_class))
      end
    end

    def parse_options!
      OptionParser.new { |opts| configure_parser(opts) }.then { |p| @paths = p.parse(@argv) }
    end

    def configure_parser(opts)
      opts.banner = USAGE
      default = Assistant::RbsGenerator::DEFAULT_OUTPUT_DIR
      opts.on('-o', '--output DIR', "Output directory (default: #{default})") do |dir|
        @output_dir = dir
      end
      opts.on('-q', '--quiet', 'Suppress non-error output') { @quiet = true }
      opts.on('-h', '--help', 'Show this message') do
        @stdout.puts opts
        raise SystemExit, 0
      end
    end

    def load_paths(paths)
      paths.each do |path|
        if File.directory?(path)
          Dir.glob(File.join(path, '**/*.rb')).each { |file| safe_require(file) }
        elsif File.file?(path)
          safe_require(path)
        else
          @stderr.puts "[warn]      no such file or directory: #{path}"
        end
      end
    end

    def safe_require(path)
      require File.expand_path(path)
    rescue LoadError, StandardError => e
      @stderr.puts "[warn]      failed to load #{path}: #{e.class}: #{e.message}"
    end

    # Snapshot of every loaded Service subclass. Used to diff before /
    # after `load_paths` so we only emit signatures for classes whose
    # source files we were actually asked to scan -- this keeps a
    # long-running process (or a test suite) from re-emitting sigs for
    # every Service subclass it has ever seen.
    def service_subclasses
      ObjectSpace.each_object(Class).select { |klass| klass < Assistant::Service && klass.name }
    end
  end
end

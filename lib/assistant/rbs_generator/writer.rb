# frozen_string_literal: true

require 'fileutils'

module Assistant::RbsGenerator
  # File-writing layer with marker-aware idempotency.
  class Writer
    def initialize(output_dir:, quiet: false, stdout: $stdout, stderr: $stderr)
      @output_dir = output_dir
      @quiet = quiet
      @stdout = stdout
      @stderr = stderr
    end

    # Returns one of :written, :unchanged, :skipped.
    def write(service_class, contents)
      target = path_for(service_class)
      return skip!(target) if exists_without_marker?(target)
      return unchanged!(target) if File.exist?(target) && File.read(target) == contents

      FileUtils.mkdir_p(File.dirname(target))
      File.write(target, contents)
      announce("[written]   #{target}")
      :written
    end

    private

    attr_reader :output_dir, :quiet, :stdout, :stderr

    def exists_without_marker?(target)
      File.exist?(target) && !generated_file?(target)
    end

    def skip!(target)
      stderr.puts "[skipped]   #{target} (no generator marker; will not overwrite)"
      :skipped
    end

    def unchanged!(target)
      announce("[unchanged] #{target}")
      :unchanged
    end

    def path_for(service_class)
      name = service_class.name or raise "anonymous Service class #{service_class.inspect}"
      relative = name.split('::').map { |seg| underscore(seg) }.join('/')
      File.join(output_dir, "#{relative}.rbs")
    end

    # ASCII-only underscoring -- the gem ships no runtime deps, so this
    # mirrors the common ActiveSupport rule without pulling it in.
    def underscore(camel)
      camel.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
    end

    def generated_file?(path)
      File.foreach(path).first&.chomp == Assistant::RbsGenerator::MARKER
    end

    def announce(message)
      stdout.puts(message) unless quiet
    end
  end
end

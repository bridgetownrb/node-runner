require "tmpdir"
require "open3"
require "json"

class NodeRunnerError < StandardError; end

class NodeRunner
  def initialize(source = "", options = {})
    @source  = encode(source.strip)
    @args = options[:args] || {}
    @executor = options[:executor] || NodeRunner::Executor.new
    @function_name = options[:function_name] || "main"
  end
  
  def output
    exec
  end
  
  def method_missing(m, *args, &block)
    @function_name = m
    if block
      @source = encode(block.call.strip)
    end
    @args = *args
    exec
  end

  protected

  def encode(string)
    string.encode('UTF-8')
  end
  
  def exec
    source = @executor.compile_source(@source, @args.to_json, @function_name)
    tmpfile = write_to_tempfile(source)
    filepath = tmpfile.path

    begin
      extract_result(@executor.exec(filepath), filepath)
    ensure
      File.unlink(tmpfile)
    end
  end

  def create_tempfile(basename)
    tmpfile = nil
    Dir::Tmpname.create(basename) do |tmpname|
      mode    = File::WRONLY | File::CREAT | File::EXCL
      tmpfile = File.open(tmpname, mode, 0600)
    end
    tmpfile
  end

  def write_to_tempfile(contents)
    tmpfile = create_tempfile(['node_runner', 'js'])
    tmpfile.write(contents)
    tmpfile.close
    tmpfile
  end

  def extract_result(output, filename)
    status, value, stack = output.empty? ? [] : ::JSON.parse(output, create_additions: false)
    if status == "ok"
      value
    else
      stack ||= ""
      real_filename = File.realpath(filename)
      stack = stack.split("\n").map do |line|
        line.sub(" at ", "")
            .sub(real_filename, "node_runner")
            .sub(filename, "node_runner")
            .strip
      end
      stack.shift # first line is already part of the message (aka value)
      error = NodeRunnerError.new(value)
      error.set_backtrace(stack + caller)
      raise error
    end
  end
end

class NodeRunner::Executor
  attr_reader :name

  def initialize(options = {})
    @command      = options[:command] || ['node']
    @modules_path = options[:modules_path] || File.join(Dir.pwd, "node_modules")
    @runner_path  = options[:runner_path] || File.join(File.expand_path(__dir__), '/node_runner.js')
    @encoding     = options[:encoding] || "UTF-8"
    @binary       = nil

    @popen_options = {}
    @popen_options[:external_encoding] = @encoding if @encoding
    @popen_options[:internal_encoding] = ::Encoding.default_internal || 'UTF-8'

    if @runner_path
      instance_eval generate_compile_method(@runner_path)
    end
  end

  def exec(filename)
    ENV["NODE_PATH"] = @modules_path
    stdout, stderr, status = Open3.capture3("#{binary} #{filename}")
    if status.success?
      stdout
    else
      raise exec_runtime_error(stderr)
    end
  end
  
  protected

  def binary
    @binary ||= which(@command)
  end

  def locate_executable(command)
    commands = Array(command)

    commands.find { |cmd|
      if File.executable? cmd
        cmd
      else
        path = ENV['PATH'].split(File::PATH_SEPARATOR).find { |p|
          full_path = File.join(p, cmd)
          File.executable?(full_path) && File.file?(full_path)
        }
        path && File.expand_path(cmd, path)
      end
    }
  end

  def generate_compile_method(path)
    <<-RUBY
    def compile_source(source, args, func)
      <<-RUNNER
      #{IO.read(path)}
      RUNNER
    end
    RUBY
  end

  def encode_source(source)
    encoded_source = encode_unicode_codepoints(source)
    ::JSON.generate("(function(){ #{encoded_source} })()", quirks_mode: true)
  end

  def encode_unicode_codepoints(str)
    str.gsub(/[\u0080-\uffff]/) do |ch|
      "\\u%04x" % ch.codepoints.to_a
    end
  end

  def exec_runtime_error(output)
    error = RuntimeError.new(output)
    lines = output.split("\n")
    lineno = lines[0][/:(\d+)$/, 1] if lines[0]
    lineno ||= 1
    error.set_backtrace(["(node_runner):#{lineno}"] + caller)
    error
  end

  def which(command)
    Array(command).find do |name|
      name, args = name.split(/\s+/, 2)
      path = locate_executable(name)

      next unless path

      args ? "#{path} #{args}" : path
    end
  end
end

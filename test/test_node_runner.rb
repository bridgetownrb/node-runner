require "minitest/autorun"
require "node-runner"

class TestNodeRunner < Minitest::Test
  extend Minitest::Spec::DSL

  let(:runner) do NodeRunner.new(
      <<~NODE
        const hello = (response) => {
          return `Hello? ${response}!`
        }
      NODE
    )
  end

  def test_that_simple_functions_work
    results = runner.hello("Goodbye")

    assert_equal "Hello? Goodbye!", results
  end
  
  def test_that_missing_args_still_work
    results = runner.hello

    assert_equal "Hello? undefined!", results
  end
  
  def test_that_wrong_function_name_shows_stacktrace
    error = assert_raises(NodeRunnerError) do
      runner.nothing
    end

    assert_equal "ReferenceError: nothing is not defined", error.message
  end
  
  def test_execjs_style_invocation
    script = <<~NODE
      const main = (response) => {
        return `Hello? ${response}!`
      }
    NODE
    execjs_style_runner = NodeRunner.new(script, args: ["Goodbye"])

    assert_equal "Hello? Goodbye!", execjs_style_runner.output
  end
  
  let(:runner_with_hash) do NodeRunner.new(
      <<~NODE
        const hello = (response) => {
          return {value: {string: `Hello? ${response}!`}}
        }
      NODE
    )
  end
  
  def test_that_nested_hashes_work
    results = runner_with_hash.hello("Goodbye")

    assert_equal "Hello? Goodbye!", results["value"]["string"]
  end
  
  let(:runner_with_requires) do NodeRunner.new(
      <<~NODE
        const path = require("path")
        const extname = (filename) => {
          return path.extname(filename);
        }
      NODE
    )
  end
  
  def test_that_requires_work
    results = runner_with_requires.extname("README.md")

    assert_equal ".md", results
  end

  let(:runner_with_promises) do NodeRunner.new(
      <<~NODE
        const hello = (response) => {
          return new Promise((resolve, reject) => {
            resolve(`Hello? ${response}!`)
          })
        }
      NODE
    )
  end

  def test_that_promises_work
    results = runner_with_promises.hello("Goodbye")

    assert_equal "Hello? Goodbye!", results
  end
end

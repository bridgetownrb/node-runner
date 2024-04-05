# NodeRunner for Ruby

A simple way to execute Javascript in a Ruby context via Node. (Loosely based on the Node Runtime module from [ExecJS](https://github.com/rails/execjs).)

[![Gem Version](https://badge.fury.io/rb/node-runner.svg)](https://badge.fury.io/rb/node-runner)

## Installation

Run this command to add this plugin to your project's Gemfile:

```shell
$ bundle add node-runner
```

For [Bridgetown](https://www.bridgetownrb.com) websites, you can run an automation to install NodeRunner and set up a builder plugin for further customization.

```shell
bin/bridgetown apply https://github.com/bridgetownrb/node-runner
```

## Usage

Simply create a new `NodeRunner` object and pass in the Javascript code you wish to
execute:

```ruby
require "node-runner"

runner = NodeRunner.new(
  <<~JAVASCRIPT
    const hello = (response) => {
      return `Hello? ${response}`
    }
  JAVASCRIPT
)
```

Then call the function as if it were a genuine Ruby method:

```ruby
runner.hello "Goodbye!"

# output: "Hello? Goodbye!"
```

Under the hood, the data flowing in and out of the Javascript function is translated via JSON, so you'll need to stick to standard JSON-friendly data
values (strings, integers, arrays, hashes, etc.)

You can also use Node require statements in your Javascript:

```ruby
runner = NodeRunner.new(
  <<~JAVASCRIPT
    const path = require("path")
    const extname = (filename) => {
      return path.extname(filename);
    }
  JAVASCRIPT
)
  
extname = runner.extname("README.md")

extname == ".md"

# output: true
```

Multiple arguments for a function work, as do multiple function calls (aka
if you define `function_one` and `function_two` in your Javascript, you can call
`runner.function_one` or `runner.function_two` in Ruby).

## Node Executor Options

If you need to customize which `node` binary is executed, or wish to use your
own wrapper JS to bootstrap the `node` runtime, you can pass a custom instance
of `NodeRunner::Executor` to `NodeRunner`:

```ruby
NodeRunner.new "…", executor: NodeRunner::Executor.new(command: "/path/to/custom/node")
```

`command` can be an array as well, if you want to attempt multiple paths until one is found. Inspect the `node-runner.rb` source code for more information on the available options.

## Caveats

A single run of a script is quite fast, nearly as fast as running a script directly with the
`node` CLI…because that's essentially what is happening here. However, the performance characteristics using
this in a high-traffic request/response cycle (say, from a Rails app) is unknown. Likely the best context to use
Node Runner would be via a background job, or during a build process like when using a static site generator.
(Like our parent project [Bridgetown](https://github.com/bridgetownrb/bridgetown)!)

## Testing

* Run `bundle exec rake` to run the test suite.

## Contributing

1. Fork it (https://github.com/bridgetownrb/node-runner/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

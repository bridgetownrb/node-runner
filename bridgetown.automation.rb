run "bundle add node-runner", abort_on_failure: false

builder_file = "node_script_builder.rb"
create_builder builder_file do
  <<~RUBY
    require "node-runner"

    class NodeScriptBuilder < SiteBuilder
      def build
        # access output in Liquid with {{ site.data.node_script.hello }}
        add_data "node_script" do
          runner = NodeRunner.new(
            <<~JAVASCRIPT
              const hello = (response) => {
                return `Hello? ${response}`
              }
            JAVASCRIPT
          )
          
          {
            hello: runner.hello("Goodbye!")
          }
        end
      end
    end
  RUBY
end

say_status "node-runner", "Installed! Check out plugins/builders/#{builder_file} to customize your Node script"

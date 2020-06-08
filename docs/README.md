# Getting Started

To get started with Kerbi, create an empty directory with a Gemfile containing:

```ruby
source 'https://rubygems.org'
gem 'kerbi'
```

After running `bundle install` create a `main.rb` and `values.yaml` such that your directory is:
```
├───Gemfile
├───main.rb
├───values
│   └───values.yaml
```  

At this point we can make sure everything works by creating our first mixer in `main.rb`:

```ruby
require 'kerbi'

class HelloWorldMixer < Kerbi::Mixer
  def run
    super do |g|
      g.hash hello: "I am #{values[:status] || "almost"} templating with Kerbi"
    end
  end
end

kerbi.generators = [ HelloWorldMixer ]
puts kerbi.gen_yaml
```

And our first values in `values/values.yaml`:
```yaml
status: "successfully"
```

Then, run your `main.rb` as you would any Ruby script:

```bash
ruby main.rb 
# or
bundle exec ruby main.rb
```

The output should be 
```yaml
hello: "I am successfully templating with Kerbi"
```

## Next: Values

Continue onto [values in Kerbi](values.md).
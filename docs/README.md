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

At this point we can make sure everything works by creating our first generator in `main.rb`:

```ruby
require 'kerbi'

class OurFirstGen < Kerbi::Mixer
  def gen
    { foo: values[:foo] }
  end
end

kerbi.generators = [ OurFirstGen ]
puts kerbi.gen_yaml
```

And our first values in `values/values.yaml`:
```yaml
foo: bar
```

Then, run your `main.rb` as you would any Ruby script:

`$ ruby main.rb` or `$ bundle exec ruby main.rb`


# Subclassing a Mixer

Most of the action in your `Kerbi::Mixer` subclasses happens in the `run` function. 
Before going there, it's useful to understand `Kerbi::Mixer` as a whole.

## How Mixers are consumed 

As a user, you don't typically instantiate your `Kerbi::Mixer` subclasses. 
Instead, you pass a list of the class objects to Kerbi: 
```ruby
# main.rb
require 'kerbi'

class MixerOne < Kerbi::Mixer; end
class MixerTwo < Kerbi::Mixer; end

kerbi.generators = [MixerOne, MixerTwo]
```

## Accessing the Values hash

Once instantiated, a `Kerbi::Mixer` subclass can access the values
 [aggregated by Kerbi](values.md) in the form of a **symbol**-keyed hash via the
`self.values` accessor.

With `values.yaml`,
```yaml
backend:
  replicas: 3
```

A generator method that prints out its values: 

```ruby
class MixerOne < Kerbi::Mixer
  def print_values
    puts self.values
    # => {backend: {replicas: 3}}
  end
end
```

## Pointing Kerbi to adjacent YAMLs

You will most likely use your `Kerbi::Mixer` subclasses to inflate
yamls you have defined nearby. 

Assume the following directory structure:

```bash
├───Gemfile
├───main.rb
├───machine-learning
│   ├───mixer.rb
│   ├───service.yaml.erb
│   └───replicaset.yaml
├───values
│   └───values.yaml
```

And the following `MachineLearning::Mixer` class:

```ruby
module MachineLearning
  class Mixer < Kerbi::Mixer

    locate_self __dir__ #thanks to this

    def run
      super do |g|
        g.yaml 'service'
        g.yaml 'replicaset' 
      end
    end
  end
end
``` 

Ignoring the details of `super do` and `g.yaml` for now, notice that
we can point to files in our current directory. 

For this to work,
**need to call** the class method `locate_self` in your subclass. 


## Limiting values to a subtree

It often makes sense to limit a particular `Kerbi::Mixer` subclass's access to
a particular subtree of the global values tree.
This is accomplished by overriding the constructor - `initialize`.

In this example, we limit `FrontendMixer` to the `frontend` subtree.

```yaml
backend:
  #...don't want this in FrontendGen
frontend:
  deployment:
    replicas: 3
  service:
    type: NodePort
```    

Corresponding generator:

```ruby
class FrontendGen < Kerbi::Mixer
  def initialize(values)
    super(values[:frontend])
  end
  
  def print_values
    puts self.values
    # => {deployment: {replicas: 3}, service: {type: 'NodePort'}}
  end
end
```

## Writing Helpers

The `Kerbi::Mixer` class is a simple Ruby object; you can decorate
subclasses with any helper methods you need to perform extra logic.

Below are common use cases:

#### Convenient Accessors

To keep ERB's clean, it can be useful to write anything more than a trivial 
`values[:foo]` as a dedicated instance method:


```ruby
class BackendMixer < Kerbi::Mixer
  def ingress_enabled?
    values&.dig(:networking, :type) == 'ingress'
  end
end
``` 
 
#### Defensive Access

Leveraging Ruby's safe navigation and hash accessors:

```ruby
class PostgresMixer < Kerbi::Mixer
  def pg_secrets_ready?
    root = values&.dig(:storage, :secrets) || {}
    user, password = root[:user], root[:password]
    user.present? && password.present?
  end
end
``` 





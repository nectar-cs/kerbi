
# Subclassing Gen

Most of the action in your `Kerbi::Gen` subclasses happens in the `gen` function. 
Before going there, it's useful to know how `Kerbi::Gen` subclasses work at a high level.

## How Gens are consumed 

As a user, you don't typically instantiate your `Kerbi::Gen` subclasses. 
Instead, you pass a list of the class objects to Kerbi: 
```ruby
require 'kerbi'

class GenOne < Kerbi::Gen; end
class GenTwo < Kerbi::Gen; end

kerbi.generators = [GenOne, GenTwo]
```

## Accessing the Values hash

Once instantiated, a `Kerbi::Gen` subclass can access the values
 [aggregated by Kerbi](values.md) in the form of a **symbol**-keyed hash via the
`self.values` accessor.

With `values.yaml`,
```yaml
backend:
  replicas: 3
```

A generator that simply returns its values

```ruby
class GenOne < Kerbi::Gen
  def print_values
    puts self.values
    # => {backend: {replicas: 3}}
  end
end
```

## Telling Kerbi about adjacent YAMLs

You will most likely use your `Kerbi::Gen` subclasses to inflate
yamls you have defined nearby. 

Assume the following directory structure:

```bash
├───Gemfile
├───main.rb
├───machine-learning
│   ├───gen.rb
│   ├───service.yaml.erb
│   └───replicaset.yaml
├───values
│   └───values.yaml
```

And the following `MachineLearning::Gen` class:

```ruby
module MachineLearning
  class Gen < Kerbi::Gen

    locate_self __dir__ #thanks to this

    def gen
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


## Using a Values subtree

It often makes sense to limit a particular `Kerbi::Gen` subclass's access to
a particular subtree of the global values tree.
This is accomplished by overriding the constructor - `initialize`.

In this example, we limit `FrontendGen` to the `frontend` subtree.

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
class FrontendGen < Kerbi::Gen
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

The `Kerbi::Gen` class is a simple Ruby object; you can decorate
subclasses with any and all the helper methods you need to perform extra logic.

Below are common use cases:

#### Convenient Accessors



```ruby
class BackendGen < Kerbi::Gen
  def ingress_enabled?
    values&.dig(:networking, :type) == 'ingress'
  end
end
``` 
 
#### Defensive Access

Leveraging Ruby's safe navigation and hash accessors:

```ruby
class PostgresGen < Kerbi::Gen
  def pg_secrets_ready?
    root = values&.dig(:storage, :secrets) || {}
    user, password = root[:user], root[:password]
    user.present? && password.present?
  end
end
``` 







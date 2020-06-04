
# The Gen Class

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

## Locating 


## Using a Values subtree

It often makes sense to limit a particular `Kerbi::Gen` subclass's access to
a particular subtree of the values tree.
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

#### Value Cleaners

Leveraging Ruby's safe navigation and hash accessors:

```ruby
class BackendGen < Kerbi::Gen
  def ingress_enabled?
    values&.dig(:networking, :type) == 'ingress'
  end
end
``` 
 








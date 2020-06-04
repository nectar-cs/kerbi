# Templating

You can make Kerbi generate the same YAML in many different ways by combining 
the different methods. 

This page documents each strategy individually; for inspiration on how to 
leverage multiple methods, check out the examples directory.

## The gen method

The `Kerbi::Gen#gen` method is where it all happens. Kerbi translates the 
method's return value into yaml.

**The way you should** use `gen` is to pass it a block and make
calls to the builder it passes. 

```ruby
class GenWithSuperDo < Kerbi::Gen
  def gen
    super do |g|
      g.hash foo: 'bar'
      g.yaml 'some-file'
      g.yamls in: 'some-dir'
      g.patched_with yamls: %[a-patch-file] do |pg|
        pg.hash foo: 'i-may-get-patched'
      end 
    end
  end
end
```

The `g` in `super do |g|` is known as an aggregator. It amasses the
results of your invocations and returns an array. The functions it exposes - 
`hash`, `yaml`, `yamls`, `patched_with` - all return arrays of hashes.


## Loading YAML files

You can use the same `g.yaml <fname>` call to load YAML and ERB files alike.

ERB files are loaded with the current class context, which includes the `values`
accessor, as well as any custom methods you provide.

Here is an example with two resources, one `.yaml`, one `.yaml.erb`.

```yaml
#role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: dummy-role
rules: []
```

```yaml
#role.yaml.erb
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: role-binding
subjects:
- kind: <%= subject_kind %>
  name: <%= values[:user] %>
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: dummy-role
  apiGroup: rbac.authorization.k8s.io
```

Our generator would look like:

```ruby
class RbacGen < Kerbi::Gen
  locate_self __dir__
  
  def gen
    super do |g|
      g.yaml 'role'
      g.yaml 'role-binding'
    end
  end
  
  def subject_kind
    some_condition ? 'User' : 'Group'
  end
end
```

The `g.yaml` method also accepts an `extra` hash that allows for 
last minute customization.

## Loading YAMLS from a directory

You can load every YAML and ERB file (non-recursively) from 
a directory with `g.yamls`. 

Take the following project:

```bash
├───Gemfile
├───main.rb
├───storage
│   ├───postgres-deployment.yaml.erb
│   └───postgres-service.yaml.erb
├───machine-learning
│   ├───gen.rb
│   ├───service.yaml.erb
│   └───replicaset.yaml
├───values
│   └───values.yaml
```

The following generator loads the yaml files in `storage` and `machine-learning`:

```ruby
module MachineLearning
  class Gen < Kerbi::Gen
    locate_self __dir__
  
    def gen
      super do |g|
        g.yamls in: './../storage'
        g.yamls
      end
    end
  end
end
```

When `in` is passed to to `yamls`, it searches that directors (starting with `.` indicates relative).

Otherwise the current dir, according to `locate_self`, is searched.

## Loading Hashes

The most direct way of passing  





## Using Patches
# Templating

You can make Kerbi generate the same YAML in many different ways by combining 
the different methods. 

This page documents each strategy individually; for inspiration on how to 
leverage multiple methods, check out the examples directory.

## The gen method

The `Kerbi::Mixer#run` method is where it all happens. Kerbi translates the 
method's return value into yaml.

**The way you should** use `gen` is to pass it a block and make
calls to the builder it passes. 

```ruby
class MixerWithSuperDo < Kerbi::Mixer
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
class RbacMixer < Kerbi::Mixer
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
#machine-learning/gen.rb
module MachineLearning
  class Mixer < Kerbi::Mixer
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

When `in: <dir-name>` is passed to to `yamls`, it looks for `*.yaml` and `*.yaml.erb`
files in `<dir-name>`. If `in: <dir-name>` is not passed, it looks in the current
directory, according to `locate_self`.



## Loading Hashes

The third option is to pass in actual Ruby hashes.   

```ruby
#foundation/gen.rb
class FoundationsMixer < Kerbi::Mixer
  locate_self __dir__
  
  def gen
    super do |g|
      values[:org][:developers].each do |developer|
        g.hash self.template_namespace(developer)
      end
    end
  end

  def template_namespace(name)
    {
      kind: 'Namespace',
      metadata: { name: name }
    }
  end
end
```


## Using Patches

With a `patch_with` block, you can merge hashes onto the hashes being loaded
in your block.

A very simple example: 
```ruby
class TrivialPatchMixer < Kerbi::Mixer
  def gen
    super do |g|
      g.hash foo: 'foo'
      g.patched_with hash: {foo: 'you-got-patched'} do |gp|
        gp.hash foo: 'bar', bar: 'bar'
      end
    end
  end
end
```

Kerbi would output 

```yaml
foo: bar
---
foo: you-got-patched
bar: bar
```

The `patched_with` accepts different patch sources:

| keyword  | expects                             |
|----------|-------------------------------------|
| hash     | single hash                         |
| hashes   | array of hashes                     |
| yamls    | array of yaml filenames             |
| yamls_in | single name of dir containing yamls |

`yamls` and `yamls_in` use the same filename resolution logic detailed above.


## Loading YAML from Helm Charts

Kerbi can injest output from the `helm template` command if you point
it to a repo.

```ruby
class BackendMixer < Kerbi::Mixer
  def run
    super do |g|
      g.chart id: 'stable/prometheus'
    end
  end
end
```

| name           | notes                                                                       | default | required |   |
|----------------|-----------------------------------------------------------------------------|---------|----------|---|
| id             | charts as identified by helm: <org/chart-name>                              | `nil`   | true     |   |
| release        | value many charts use for interpolation                                     | "kerbi" | false    |   |
| values         | hash to be serialized to a temp values.yaml file passed to helm as `-f`     | `{}`    | false    |   |
| inline_assigns | deep-key hash passed to helm with --set e.g `{"service.type": "ClusterIP"}` | `{}`    | false    |   |
| cli_args       | string to be passed in `helm template` command e.g "--atomic --replace"     | `nil`   | false    |   |
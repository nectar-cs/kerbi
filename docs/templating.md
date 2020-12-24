# Templating

A mixer injests different formats - `yaml` files, `yaml.erb` files, Helm charts, 
ruby hashes, and remote files - loads them into memory, parses them, 
and outputs them as an array of hashes. 

This page documents the methods available for injesting.

For comprehensive documentation, refer to the 
[ResBucket](https://www.rubydoc.info/gems/kerbi/Kerbi/ResBucket) and
[Mixer](https://www.rubydoc.info/gems/kerbi/Kerbi/Mixer) docs on RubyGems.

### The run method

The `Kerbi::Mixer#run` method is where all injesting and mixing must happen. 





#### Run with the aggregator

**The standard way to** use `run` is to pass it a aggregator and make
calls to the builder it passes.

```ruby
class TypicalMixer < Kerbi::Mixer
  def run
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

The `g` in `super do |g|` is an aggregator of type `Kerbi::ResBucket`. The functions it exposes - 
`hash`, `yaml`, `yamls`, `patched_with`, `chart`, `github, `mixer` - all 
produce and lists of hashes and add them immediately to the bucket `g`. See the
api docs for a complete description.





#### Run without the aggregator

In some cases, you'll need to injest hashes without adding 
them directly to the bucket. For instance, you'd like to load the contents of a 
YAML file, change values, and then submit the processed objects.

In this case, you'll want to call the `Kerbi::Mixer` instance methods directly. 
See the api docs for the complete list of methods in `Kerbi::Mixer`. For example:

```ruby
class MixerWithDirectCalls < Kerbi::Mixer
  def run
    super do |g|
      from_yaml = self.inflate_yaml_file('my-file', [], [], {})
      from_yaml.first['metadata']['annotations'].merge!(
        new_annotation: 'new-value'        
      )
      g.hashes from_yaml    
    end    
  end    
end
```



## Loading YAML files

Use `g.yaml <fname>` to load YAML and ERB files alike. 

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

Our Mixer would look like:

```ruby
class RbacMixer < Kerbi::Mixer
  locate_self __dir__
  
  def run
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
last minute customization:

```ruby
class YamlMixerWithExtras < Kerbi::Mixer
  def run
    super do |g|
      g.yaml 'namespace', extras: { owner: 'jack' }
    end
  end
end
```

The extras hash can be accessed in ERB as a hash:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: "<%= extras[:owner] %>-devspace"
```

Comprehensive method 
[documentation](https://www.rubydoc.info/gems/kerbi/Kerbi/ResBucket#yaml-instance_method).






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
│   ├───mixer.rb
│   ├───service.yaml.erb
│   └───replicaset.yaml
├───values
│   └───values.yaml
```

The Mixer below loads the yaml files in `storage` and `machine-learning`. 
Notice that our class must call `locate_self` in order to tell the Mixer
where it is in the project hierarchy.

```ruby
#machine-learning/mixer.rb
module MachineLearning
  class Mixer < Kerbi::Mixer
    locate_self __dir__
  
    def run
      super do |g|
        g.yamls in: './../storage'
        g.yamls except: 'service.yaml.erb' #'in' is not passed, search current dir
      end
    end
  end
end
```

When `in: <dir-name>` is passed to to `yamls`, it looks for `*.yaml` and `*.yaml.erb`
files in `<dir-name>`. 

If `in: <dir-name>` is not passed, it looks in the current
directory, according to `locate_self`.

Comprehensive method 
[documentation](https://www.rubydoc.info/gems/kerbi/Kerbi/ResBucket#yamls-instance_method).


## Loading Hashes

Mixers can of course injest ruby hashes as well.   

```ruby
#foundation/mixer.rb
class DevNamespacesMixer < Kerbi::Mixer
  def run
    super do |g|
      values[:org][:developers].each do |developer|
        g.hash self.namespace_res_hash(developer)
      end
    end
  end

  def namespace_res_hash(name)
    {
      kind: 'Namespace',
      metadata: { name: name }
    }
  end
end
```

Comprehensive method 
[documentation](https://www.rubydoc.info/gems/kerbi/Kerbi/ResBucket#hash-instance_method).





## Using Patches

With a `patched_with` block, you can merge hashes onto the hashes being loaded
in your block, just like with Kustomize.

A very simple example: 
```ruby
class TrivialPatchMixer < Kerbi::Mixer
  def run
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

Different sources may be given in the same call:

```ruby
class MultiPatchMixer < Kerbi::Mixer
  def run
    super do |g|
      sources = {
        hashes: [{foo: 'bar'}, {bar: 'baz'}],
        yamls: %w[company-annotations lean-resource-limits],
        yamls_in: './../application-wide-patches',                         
      }    

      g.patched_with **sources do |gp|
        gp.hash foo: 'bar', bar: 'bar'
      end
    end
  end
end
```

`yamls` and `yamls_in` use the same filename resolution logic detailed above.

Comprehensive method 
[documentation](https://www.rubydoc.info/gems/kerbi/Kerbi/ResBucket#patched_with-instance_method).






## Loading YAML from Helm Charts

Kerbi can injest output from the `helm template` command if you point
it to a repo.

```ruby
class HelmChartMixer < Kerbi::Mixer
  def run
    super do |g|
      g.chart(
        id: 'stable/prometheus',
        release: "internal",
        values: { alertmanager: { service: { type: 'ClusterIP' } } },
        inline_assigns: { "configmapReload.prometheus.enabled": true },
        cli_args: "--timeout duration 1m0s"
      )
    end
  end
end
```

| name           | notes                                                                       | default | required |
|----------------|-----------------------------------------------------------------------------|---------|----------|
| id             | charts as identified by helm: <org/chart-name>                              | `nil`   | true     |
| release        | value many charts use for interpolation                                     | "kerbi" | false    |
| values         | hash to be serialized to a temp values.yaml file passed to helm as `-f`     | `{}`    | false    |
| cli_args       | string to be passed in `helm template` command e.g "--atomic --replace"     | `nil`   | false    |


Comprehensive method 
[documentation](https://www.rubydoc.info/gems/kerbi/Kerbi/ResBucket#chart-instance_method).


#### Adding missing repos

In keeping true to Kerbi's functional nature, by default, Kerbi will not add 
missing repos if they cannot be found.

To get around this, you can add your own logic in the your entrypoint file:

```ruby
# main.rb
require 'kerbi'

system("helm repo add xxx yyy")

# run engine etc...
```

#### Configuration

You can slightly modify Kerbi's Helm behavior by changing the global config:

```ruby
# main.rb
require 'kerbi'

config.tmp_helm_values_path = '/some/other/file.yaml'
config.helm_exec ='/a/helm/binary'

# run engine etc...
```

By default, `tmp_helm_values_path` is '/tmp/kerbi-helm-vals.yaml'. This 
is the file that Kerbi writes your `values` hash passed in the `chart` call. 
The file is delete as soon as the `helm template` system call has executed.






## Loading YAML from Templating APIs

A good strategy for complex pipelines is to offload some templating to a remote
API. 

```ruby

class TemplatingApiMixer < Kerbi::Mixer
  def run
    super do |g|
      g.tam_api(
        url: 'https://api.codenectar.com/ice-ream',
        version: '1.0.0'
      )        
    end
  end
end

```


| name           | notes                                                                       | default                      | required |
|----------------|-----------------------------------------------------------------------------|------------------------------|----------|
| url            | Base url for templating API **without** version or URL args                 | `nil`                        | true     |
| version        | value many charts use for interpolation                                     | `nil`                        | true     |
| release_name   | Release name (aka the namespace) for templating engine to use               | `self.values[:release_name]` | false    |
| values         | Hash of values to be passed to the templating engine                        | `self.values`                | false    |


## Loading YAML files from Github

You can point Kerbi to a YAML file inside Github project as well:

 ```ruby

class GithubFileMixer < Kerbi::Mixer
  def run
    super do |g|
      g.github(
        id: 'kubernetes/website', 
        file: 'content/en/examples/application/wordpress/mysql-deployment.yaml',  
        branch: 'master'
      )
    end
  end
end

``` 

Comprehensive method 
[documentation](https://www.rubydoc.info/gems/kerbi/Kerbi/ResBucket#github-instance_method).







## Loading output from other Mixers

You can invoke a second mixer from inside your mixer as follows:
 
 The inner mixer:
```ruby
# invoked_mixer.rb
class InvokedMixer < Kerbi::Mixer
  def run
    super do |g|
      g.hash foo: "got #{self.values[:foo]}"
    end            
  end  
end
```

The outer mixer:
```ruby
# invoking_mixer.rb
require_relative 'invoked_mixer.rb'

class InvokingMixer < Kerbi::Mixer
  def run
    super do |g|
      g.mixer InvokedMixer, root: { foo: 'bar' }
    end    
  end  
end
```

Comprehensive method 
[documentation](https://www.rubydoc.info/gems/kerbi/Kerbi/ResBucket#mixer-instance_method).

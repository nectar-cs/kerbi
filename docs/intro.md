
# Kerbi

#### What is Kerbi?
Kerbi (Kubernetes Emdedded Ruby Interpolator) is yet another templating engine for 
generating Kubernetes resource manifests. 

It enables the combined use of the three most popular templating strategies under one roof:
- embedding values and code into YAML files (e.g [Helm](https://github.com/helm/helm))
- patching and overlaying YAML files (e.g [kustomize](https://github.com/kubernetes-sigs/kustomize))
- serializing YAML from in-memory objects (e.g [jsonnet](https://github.com/google/jsonnet))

Much like in the language it uses - Ruby - Kerbi is easy to use, and easy to abuse. 
Kerbi is exclusively a Ruby gem, and cannot be used as a standalone executable.
  
### Install

Inside a new project's Gemfile:  

```
gem 'kerbi'
```

Then `bundle install`.


### How it works

Kerbi generates YAML from other YAMLs, [ERB](https://www.stuartellis.name/articles/erb/), 
Ruby files, and entire directories. As a user, you write `Gen` Ruby classes
to orchestrate the templating.  

Conceptually, Kerbi is most similar to Helm. You create a `values.yaml` file and 
`charts`. Except that in Kerbi, a) charts are programmatic `generators` that can do
a lot more, and b) there is no required directory structure.


```ruby
class Main < Kerbi::Gen
  def gen
    {}
  end 
end

kerbi.generators = [ Main ]
puts kerbi.gen_yaml 
```

#### Why Ruby?

Ruby gets a lot of flak for being lawless and undebuggable. Rightly so. But if there's
one thing Ruby does right, it's configuration DSLs.

### What it does

Generators make it easy to orchestrate complex (and potentially bad) templating strategies:    

```ruby
class WorkloadsGen < Kerbi::Gen
  def gen
    super do |g|
      g.yaml 'metrics' if self.values[:metrics][:enabled]
      g.patched_with hashes: [limits, replicas] do |patched|
        patched.hash build_daemonset
        patched.yamls in: './../pod-charts', except: ['my-pod']
      end 
    end
  end
end
```

The actual hashes may come from ERB:

```erbruby
<% require "base64" %>
<% root = values[:db_secret] %>

kind: Secret
metadata:
  name: <%= root[:name] %>
data:
  password: <%= Base64.encode64(root[:password]) %>
```

Or from simple hashes:

```ruby
def secret
  {
    kind: 'Secret',
    metadata: { name: self.values[:name] },
    data: { password: Base64.encode64(root[:password]) }
  }
end
```

Or from YAMLs that you modify:

```yaml
kind: Secret
metadata:
  name:
data:
  password:
```

```ruby
def secret
  secret_hash = self.inflate_yaml 'secret'
  root = self.values[:secret]
  secret_hash.deep_set('metadata.name', root[:name])
  secret_hash.deep_set('data.password', Base64.encode64(root[:password]))
  secret_hash
end
```
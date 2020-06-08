
# Kerbi

### What it is
Kerbi (Kubernetes Emdedded Ruby Interpolator) is yet another templating engine for 
generating Kubernetes resource manifests. 

It enables the combined use of the three most popular templating strategies under one roof:
- embedding values and code into YAML files (e.g [Helm](https://github.com/helm/helm))
- patching and overlaying YAML files (e.g [kustomize](https://github.com/kubernetes-sigs/kustomize))
- serializing YAML from in-memory objects (e.g [jsonnet](https://github.com/google/jsonnet))

Much like in the language it uses - Ruby - Kerbi is easy to use, and easy to abuse. 
Kerbi is exclusively a Ruby gem, and cannot be used as a standalone executable.
  
### What it does

Generators make it easy to orchestrate complex (or complicated...) templating strategies:    

```ruby
class BackendMixer < Kerbi::Mixer
  def run
    super do |g|
      g.yamls in: './../storage'
      g.yaml 'config-map' 
      g.yaml 'app-secret'
      g.yaml 'perms' if values[:rbac]

      g.patched_with hashes: [labels], yamls: ['limits'] do |gp|
        gp.hash build_daemonset
        gp.yaml 'workloads'
      end
    end
  end 

  def labels
    { metadata: { labels: { microservice: 'auth-backend'} } }
  end
end
```

### Install

Inside a new project's Gemfile:  

```
gem 'kerbi'
```

Then `bundle install`.


### How it works

Kerbi generates YAML from other YAMLs, [ERBs](https://www.stuartellis.name/articles/erb/), 
and Ruby files. As a user, you write `Gen` Ruby classes
to orchestrate the templating.  

Conceptually, Kerbi is most similar to Helm. You create a `values.yaml` file and 
`charts`. Except that in Kerbi, a) charts are programmatic `generators` that can do
a lot more, and b) there is no required directory structure.


```ruby
class Main < Kerbi::Mixer
  def run
    {}
  end 
end

kerbi.generators = [ Main ]
puts kerbi.gen_yaml 
```

#### Why Ruby?

Ruby gets a lot of flak for being lawless and undebuggable. Rightly so. But if there's
one thing Ruby does right, it's configuration DSLs.


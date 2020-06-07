
# Kerbi

Kerbi (Kubernetes Emdedded Ruby Interpolator) is yet another templating engine for 
generating Kubernetes resource manifests. 

It enables the mixed use of the three most popular templating strategies under one roof:
- embedding values and code into YAML files (e.g [Helm](https://github.com/helm/helm))
- patching and overlaying YAML/objects (e.g [kustomize](https://github.com/kubernetes-sigs/kustomize))
- serializing YAML from in-memory objects (e.g [jsonnet](https://github.com/google/jsonnet))

Can mixing different strategies lead to abominable anti-patterns? Absolutely. But 
Kerbi is a free spirited enabler who does not judge. 

### Features
- Seamless mixing of `yaml`, `yaml.erb`, remote files, `helm` charts, and in-memory objects
- Helm-like `value.yaml`, `-f special-values.yaml`, and inline assignments `--set foo.bar=baz`
- Integrated environment logic à la Kustomize, i.e `-e production`
- Total freedom in project directory structure 

### Non-Features
- Release management à la Helm, packaging, or any kind of manifest versioning
- Interfacing with Kubernetes clusters, building images, syncing, etc... Kerbi just outputs yaml 

### How it looks

Kerbi lets you write programmatic generators to orchestrate complex (or silly) templating logic:    

```ruby
class BackendGen < Kerbi::Mixer
  def evaluate
    super do |g|
      g.yamls in: './../storage'
      g.yaml 'app-secret' if self.values[:secret]
      g.hash({kind: 'Deployment'})  #etc...

      g.patched_with yamls: ['company-annotations'] do |gp|
        gp.sibling ConfigMapMixer
        gp.chart id 'bitnami/postgresql' 
        gp.github id: 'my-org/k8s', file: 'k8s.yaml'
      end
    end
  end 
end
```

Where YAML files may be static `.yaml` or ruby-embedded `.yaml.erb`, e.g: 

```yaml
#app-secret.yaml.erb
apiVersion: v1
kind: Secret
metadata:
  namespace: <%= namespace %>
  name: backend-app
data:
  attr-enc-key: "<%= Base64.encode64(values[:secrets][:attr_enc]) %>"
```

### How it works

Kerbi generates YAML from other YAMLs, [ERBs](https://www.stuartellis.name/articles/erb/), 
and Ruby files. As a user, you write `Gen` Ruby classes
to orchestrate the templating.  

Conceptually, Kerbi is most similar to Helm. You create a `values.yaml` file and 
`charts`. Except that in Kerbi, a) charts are programmatic `generators` that can do
a lot more, and b) there is no required directory structure.


```ruby
class Main < Kerbi::Mixer
  def gen
    super do |g|
      g.hash foo: 'bar'
      g.hash foo: 'baz'
    end
  end 
end

kerbi.generators = [ Main ]
puts kerbi.gen_yaml 
# => foo: bar 
# => ---
# => foo: baz
```

### Install

Inside a new project's Gemfile:  

```
gem 'kerbi'
```

Then `bundle install`.



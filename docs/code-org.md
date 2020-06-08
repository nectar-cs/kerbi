# Organizing Kerbi Code

The whole point of Kerbi is to be free to organize things your way. 
Nevertheless, below is a collection of sensible patterns.

### With Balanced Directories

The most obvious and common pattern found across existing tools.

```bash
├───main.rb
├───common-patches
│   └───service-acct-assg.yaml.erb
│   └───org-annotations.yaml.erb
├───common-res
│   ├───empty-config-map.yaml.erb
│   └───internal-service.yaml
├───microservices
    ├───backend
    │   ├───mixer.rb
    │   └───workloads.yaml.erb
    ├───frontend
    │   ├───mixer.rb
    │   └───workloads.yaml
├───values
│   ├───production.rb
│   └───values.yaml
```

Individual gens must use relative paths to reach reference antecedent directories:
```ruby
# microservices/backend/mixer.rb
class Microservice::BackendMixer < Kerbi::Mixer
  locate_self __dir__
  
  def run
    super do |g|
      g.patched_with yamls_in: './../../common-patches' do |gp|
        gp.yaml 'workloads'
        gp.yamls in: './../../common-res'
      end
    end
  end
end
```

And the entrypoint `main.rb` must require its generators:

```ruby
# main.rb
require_relative './microservices/backend/mixer'
require_relative './microservices/frontend/mixer'

kerbi.generators = [ Microservice::BackendMixer, Microservice::FrontendMixer ]
puts kerbi.gen_yaml
```

## With Heavy Reuse

If you want things to be as programmatic as possible,
you can use feed Mixers to other Mixers:

```bash
├───main.rb
├───microservices
    ├───backend
    │   ├───mixer.rb
    │   └───workloads.yaml.erb
    ├───frontend
    │   ├───mixer.rb
    │   └───workloads.yaml
├───values
│   ├───production.rb
│   └───values.yaml
```


```ruby

``` 
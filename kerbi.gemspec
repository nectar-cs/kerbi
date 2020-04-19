Gem::Specification.new do |s|
  s.name        = 'kerbi'
  s.version     = '1.0.0'
  s.date        = '2020-04-19'
  s.summary     = "Hash manipulation for generating Kubernetes manifests."
  s.description = "Hash manipulation for generating Kubernetes manifests."
  s.authors     = ["Xavier Millot"]
  s.email       = 'xavier@codenectar.com'
  s.files       = Dir['lib/*.rb'] +  Dir['lib/templates/*.rb']
  s.homepage    = 'https://rubygems.org/gems/kerbi'
  s.license     = 'MIT'
end
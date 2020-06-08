files = ["lib/kerbi.rb"] +
  Dir['lib/main/*.rb'] +
  Dir['lib/utils/*.rb'] +
  Dir['lib/templates/*.rb']

Gem::Specification.new do |s|
  s.name        = 'kerbi'
  s.version     = '1.1.04'
  s.date        = '2020-04-19'
  s.summary     = "Multi-source, multi-strategy Kubernetes manifest generator."
  s.description = "Multi-source, multi-strategy Kubernetes manifest generator."
  s.authors     = ["Xavier Millot"]
  s.email       = 'xavier@codenectar.com'
  s.files       = files
  s.homepage    = 'https://nectar-cs.github.io/kerbi'
  s.license     = 'MIT'
end
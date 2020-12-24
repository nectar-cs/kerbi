files = ["lib/kerbi.rb"] +
  Dir['lib/main/*.rb'] +
  Dir['lib/utils/*.rb'] +
  Dir['lib/templates/*.rb']

Gem::Specification.new do |s|
  s.name        = 'kerbi'
  s.version     = '1.1.27'
  s.date        = '2020-04-19'
  s.summary     = "Multi-strategy Kubernetes manifest templating engine."
  s.description = "Kerbi is a Multi-source, multi-strategy Kubernetes manifest templating engine."
  s.authors     = ["Xavier Millot"]
  s.email       = 'xavier@codenectar.com'
  s.files       = files
  s.homepage    = 'https://nectar-cs.github.io/kerbi'
  s.license     = 'MIT'
end
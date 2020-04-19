require 'tempfile'
require 'simplecov'

def tmp_file(content)
  f1 = Tempfile.new
  f1 << content
  f1.rewind
  f1.path
end

def two_yaml_files(c1, c2, helper: Help.new)
  f1 = tmp_file(YAML.dump(c1))
  f2 = tmp_file(YAML.dump(c2))
  ARGV.replace ['-f', f1, '-f', f2]
  subject.load(helper)
end

class Help
  def help()'delivered' end
  def get_binding() binding end
end

SimpleCov.start


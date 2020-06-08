class BackendMixer < Kerbi::Mixer

  locate_self __dir__

  def run
    patch_dir = './../common-patches'

    super do |g|
      g.patched_with yamls_in: patch_dir do |gp|
        gp.yamls in: './../common-resources'
        gp.yamls
      end
    end
  end
end
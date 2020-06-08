require_relative './../../lib/kerbi'

class HelmChartExample < Kerbi::Mixer

  locate_self __dir__

  def run
    super do |g|
      g.chart(
        id: 'stable/prometheus',
        only: ["Deployment:kerbi-kube-state-metrics"]
      )

      g.chart(
        id: 'stable/anchore-engine',
        release: 'example',
        cli_args: "--no-hooks",
        only: ['PersistentVolumeClaim:example-postgresql']
      )

      g.hashes self.modified_helm_chart
    end
  end

  def modified_helm_chart
    my_sql_resources = self.run_with_bucket do |g|
      g.chart id: 'stable/mysql', only: ['ConfigMap:kerbi-mysql-test']
    end

    my_sql_resources.map do |res|
      res[:metadata].merge!(annotations: {}) && res
    end
  end
end

kerbi.generators = [HelmChartExample]

output = kerbi.gen_yaml
puts output
File.open("#{__dir__}/output.yaml", "w") { |f| f.write(output) }
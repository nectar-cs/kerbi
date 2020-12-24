# Values in Kerbi

Values in Kerbi are almost identical to values in Helm: arbitrary
 key-value assignments that can be referenced at templating time.

When you run `kerbi.gen_yaml`, Kerbi loads values from various sources and 
makes them available to your generators.

Kerbi aggregates values from the following places:
1. [the default values file](#the-default-values-file-path)
2. [the environment values file](#the-environment-values-file) 
2. [explicit value file paths](#explicit-value-file-paths)
2. [inline value assignments](#inline-value-assignments)

Values can be nested: 
```yaml
networking:
  ingress:
    enabled: false
```

And dynamic with ERB:

```yaml
secrets:
  password: <%= ENV['MYSQL_DEV_PW'] %>
```

## The Default Values File Path

Kerbi will attempt to open the following files and load the **first** one it finds:

```bash
├───values.yaml
├───values.yaml.erb
├───values
│   ├───values.yaml
│   └───values.yaml.erb
```

## The Environment Values File

Kerbi has the notion of **environments**, e.g dev, staging, test, etc...

Passing the `-e <env-name>` command-line flag tells Kerbi to look for the matching file using
the same search logic as before:

```bash
├───<env-name>.

├───<env-name>.yaml.erb
├───values
│   ├───<env-name>.yaml
│   └───<env-name>.yaml.erb
```

**Important**: environment is computed as follows: 

```ruby
arg_value('-e') || ENV['KERBI_ENV'] || 'development'
``` 

## Explicit Value File Paths

Additional value files may be specified by commandline with the `-f <fname>` flag: 

```bash
ruby main.rb template foo -f some-client -f some-region.yaml
```

Notice that Kerbi will again try to infer the full name of the file based `fname` by
trying:

```bash
<fname> #absolute
├───<fname>
├───<fname>.yaml
├───<fname>.yaml.erb
├───values
│   ├───<fname>
│   ├───<fname>.yaml
│   └───<fname>.yaml.erb
```


## Inline Value Assignments

Finally, Kerbi supports commandline assignments given inline by `--set foo=bar`.

For nested keys, use `.` to designate levels of nesting. So:

```bash
ruby main.rb template foo --set networking.ingress.enabled=true
```

This is useful for keeping sensitive values out of version control.

## Printing out Values

Use the same `show values` command you would use in Helm:
```bash
ruby main.rb show values
```

This is a good way to debug templating issues.

## Next

Continue onto the [Mixer overview](subclassing-mixer.md).

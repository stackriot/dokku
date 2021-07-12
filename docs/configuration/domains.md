# Domain Configuration

> New as of 0.3.10

```
domains:add <app> <domain> [<domain> ...]      # Add domains to app
domains:add-global <domain> [<domain> ...]     # Add global domain names
domains:clear <app>                            # Clear all domains for app
domains:clear-global                           # Clear global domain names
domains:disable <app>                          # Disable VHOST support
domains:enable <app>                           # Enable VHOST support
domains:remove <app> <domain> [<domain> ...]   # Remove domains from app
domains:remove-global <domain> [<domain> ...]  # Remove global domain names
domains:report [<app>|--global] [<flag>]       # Displays a domains report for one or more apps
domains:set <app> <domain> [<domain> ...]      # Set domains for app
domains:set-global <domain> [<domain> ...]     # Set global domain names
```

> Adding a domain before deploying an application will result in port mappings being set. This may cause issues for applications that use non-standard ports, as those will not be automatically detected. Please refer to the [proxy documentation](/docs/networking/proxy-management.md) for information as to how to reconfigure the mappings.

## Customizing hostnames

Applications typically have the following structure for their hostname:

```
scheme://subdomain.domain.tld
```

The `subdomain` is inferred from the pushed application name, while the `domain.tld` is set during initial dokku configuration. It can then be modified with `dokku domains:add-global` and `dokku domains:remove-global`. This value is used as a default TLD for all applications on a host.

If an FQDN such as `dokku.org` is used as the application name, the global virtualhost will be ignored and the resulting vhost URL for that application will be `dokku.org`.

You can optionally override this in a plugin by implementing the `nginx-hostname` plugin trigger. If the `nginx-hostname` plugin has no output, the normal hostname algorithm will be executed. See the [plugin trigger documentation](/docs/development/plugin-triggers.md#nginx-hostname) for more information.

## Disabling VHOSTS

If desired, it is possible to disable vhosts with the domains plugin.

```shell
dokku domains:disable node-js-app
```

On subsequent deploys, the nginx virtualhost will be discarded. This is useful when deploying internal-facing services that should not be publicly routeable. As of 0.4.0, nginx will still be configured to proxy your app on some random high port. This allows internal services to maintain the same port between deployments. You may change this port by setting `DOKKU_PROXY_PORT` and/or `DOKKU_PROXY_SSL_PORT` (for services configured to use SSL.)

The domains plugin allows you to specify custom domains for applications. This plugin is aware of any ssl certificates that are imported via `certs:add`. Be aware that disabling domains (with `domains:disable`) will override any custom domains.

```shell
# where `node-js-app` is the name of your app

# add a domain to an app
dokku domains:add node-js-app dokku.me

# list custom domains for app
dokku domains:report node-js-app

# clear all custom domains for app
dokku domains:clear node-js-app

# remove a custom domain from app
dokku domains:remove node-js-app dokku.me

# set all custom domains for app
dokku domains:set node-js-app dokku.me dokku.org
```

## Displaying domains reports for an app

> New as of 0.8.1

You can get a report about the app's domains status using the `domains:report` command:

```shell
dokku domains:report
```

```
=====> node-js-app domains information
       Domains app enabled: true
       Domains app vhosts:  node-js-app.dokku.org
       Domains global enabled: true
       Domains global vhosts: dokku.org
=====> python-app domains information
       Domains app enabled: true
       Domains app vhosts:  python-app.dokku.org
       Domains global enabled: true
       Domains global vhosts: dokku.org
=====> ruby-app domains information
       Domains app enabled: true
       Domains app vhosts:  ruby-app.dokku.org
       Domains global enabled: true
       Domains global vhosts: dokku.org
```

You can run the command for a specific app also.

```shell
dokku domains:report node-js-app
```

```
=====> node-js-app domains information
       Domains app enabled: true
       Domains app vhosts:  node-js-app.dokku.org
       Domains global enabled: true
       Domains global vhosts: dokku.org
```

You can pass flags which will output only the value of the specific information you want. For example:

```shell
dokku domains:report node-js-app --domains-app-enabled
```

## Default site

This is specific to your proxy plugin of choice. See the [nginx documentation](/docs/configuration/nginx.md#default-site) for more information on how to configure this for the default nginx proxy implementation.

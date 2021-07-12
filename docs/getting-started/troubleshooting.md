# Troubleshooting

> New as of 0.17.0

```
trace:on                                       # Enables trace mode
trace:off                                      # Disables trace mode
```

## Trace Mode

By default, Dokku will constrain the amount of output displayed for any given command run. The verbosity of output can be increased by enabling trace mode. Trace mode will turn on the `set -x` flag for bash plugins, while other plugins are free to respect the environment variable `DOKKU_TRACE` and log differently as approprate. Trace mode can be useful to see _where_ plugins are running commands that would otherwise be unexpected.

To enable trace mode, run `trace:on`

```shell
dokku trace:on
```

```
-----> Enabling trace mode
```

Trace mode can be disabled with `trace:off`

```shell
dokku trace:off
```

```
-----> Disabling trace mode
```

## Common Problems

### I deployed my app but I am getting the default nginx page.

Most of the time it's caused by some defaults newer versions of nginx set. To make sure that's the issue you're having run the following:

```shell
nginx -t
## nginx: [emerg] could not build the server_names_hash, you should increase server_names_hash_bucket_size: 32
```

If you get a similar error just edit `/etc/nginx/nginx.conf` and add the following line to your `http` section:

```nginx
http {
    (... existing content ...)
    server_names_hash_bucket_size 64;
    (...)
}
```

Note that the `server_names_hash_bucket_size` setting defines the maximum domain name length.
A value of 64 would allow domains with up to 64 characters. Set it to 128 if you need longer ones.

Save the file and try stopping nginx and starting it again:

```shell
/etc/init.d/nginx stop
## * Stopping nginx nginx                                        [ OK ]
/etc/init.d/nginx start
## * Starting nginx nginx                                        [ OK ]
```

### I want to deploy my app, but while pushing I get the following error

The following error may be emitted from a deploy:

```
! [remote rejected] master -> master (pre-receive hook declined)
```

The `remote rejected` error does not give enough information. Anything could have failed. Enable trace mode and begin debugging. If this does not help you, create a [gist](https://gist.github.com) containing the full log, and create an issue.

One the reasons why you may get this error is because the command that is run in the container exited (without errors). For example, (in Procfile) when you define a new worker container to run Delayed Job and use the bin/delayed_job start command. This command deamonizes the process and exists. The container thinks it's done so it closes itself. The error you get is the one above. To fix the above problem for Delayed Job, you must define the worker to user rake jobs:work, which doesn't deamonize the process. 

### I get the aforementioned error in the build phase (after turning on Dokku tracing)

Most errors that happen in this phase are due to transient network issues (either locally or remotely) buildpack bugs.

Find the failed phase's container image (`077581956a92` in this example).

```shell
docker ps -a  | grep build
## 94d9515e6d93        077581956a92                "/build"       29 minutes ago      Exited (0) 25 minutes ago                       cocky_bell
```

Start a new container with the failed image and poke around (i.e. ensure you can access the internet from within the container or attempt the failed command, if known).

```shell
docker run -ti 077581956a92 /bin/bash
curl -s -S icanhazip.com
## 192.168.0.1
curl http://s3pository.heroku.com/node/v0.10.30/node-v0.10.30-linux-x64.tar.gz -o node-v0.10.30-linux-x64.tar.gz
tar tzf node-v0.10.30-linux-x64.tar.gz
## ...
```

Sometimes (especially on DigitalOcean) deploying again seems to get past these seemingly transient issues. Additionally we've seen issues if changing networks that have different DNS resolvers. In this case, you can run the following to update your `resolv.conf`.

```shell
resolvconf -u
```

Please see https://github.com/dokku/dokku/issues/841 and https://github.com/dokku/dokku/issues/649.

### After adding an SSH key, I am told I cannot read from the remote repository on push

```
Connection closed by <host> port 22
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

Certain systems may have access to the `dokku` user via SSH disabled. Please check that the `dokku` user is allowed access to the system in the file `/etc/security/access.conf`. As Dokku does not manage this file, please consult your Operating System's documentation for more information.

### I want to deploy my app but I am getting asked for the password of the Git user

Sometimes the following error message may be shown on push

```
fatal: 'NAME' does not appear to be a git repository
fatal: Could not read from remote repository.
```

You get asked for a password because your SSH secret key can't be found. This may happen if the private key corresponding to the public key you added with `sshcommand acl-add` is not located in the default location `~/.ssh/id_rsa`.

You have to point SSH to the correct secret key for your domain name. Add the following to your `~/.ssh/config`:

```ini
Host DOKKU_HOSTNAME
  IdentityFile "~/.ssh/KEYNAME"
```

Also see [issue #116](https://github.com/dokku/dokku/issues/116).

### I successfully deployed my application with no deployment errors and receiving **Bad Gateway** when attempting to access the application.

In many cases the application will require the a `process.env.PORT` port opposed to a specified port.

When specifying your port you may want to use something similar to:

```javascript
var port = process.env.PORT || 3000
```

Please see https://github.com/dokku/dokku/issues/282.

### Deployment fails because of slow internet connection, messages shows `gzip: stdin: unexpected end of file`.

If you see output similar this when deploying:

```
 Command: 'set -o pipefail; curl --fail --retry 3 --retry-delay 1 --connect-timeout 3 --max-time 30 https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-2.0.0-p451-default-cache.tgz -s -o - | tar zxf -' failed unexpectedly:
 !
 !     gzip: stdin: unexpected end of file
 !     tar: Unexpected EOF in archive
 !     tar: Unexpected EOF in archive
 !     tar: Error is not recoverable: exiting now
```

it might that the cURL command that is supposed to fetch the buildpack (anything in the low megabyte file size range) takes too long to finish, due to slowish connection.  To overwrite the default values (connection timeout: 90 seconds, total maximum time for operation: 600 seconds), set the following environment variables:

```shell
dokku config:set --global CURL_TIMEOUT=1200
dokku config:set --global CURL_CONNECT_TIMEOUT=180
```

Please see https://github.com/dokku/dokku/issues/509.

Another reason for this error (although it may respond immediately ruling out a timeout issue) may be because you've set the config setting `SSL_CERT_FILE`. Using a config setting with this key interferes with the buildpack's ability to download its dependencies, so you must rename the config setting to something else, e.g. `MY_APP_SSL_CERT_FILE`.

### Build fails with `Killed` message.

This generally occurs when the server runs out of memory. You can either add more RAM to your server or setup swap space. The follow script will create 2 GB of swap space.

```shell
sudo install -o root -g root -m 0600 /dev/null /swapfile
dd if=/dev/zero of=/swapfile bs=1k count=2048k
mkswap /swapfile
swapon /swapfile
echo "/swapfile       swap    swap    auto      0       0" | sudo tee -a /etc/fstab
sudo sysctl -w vm.swappiness=10
echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf
```

### I successfully deployed my application with no deployment errors but I'm receiving Connection Timeout when attempting to access the application.

This can occur if Dokku is running on a system with a firewall like UFW enabled (some OS versions like Ubuntu have this enabled by default). You can check if this is your case by running the following script:

```shell
sudo ufw status
```

If the previous script returned `Status: active` and a list of ports, UFW is enabled and is probably the cause of the symptom described above. To disable it, run:

```shell
sudo ufw disable
```

### I can't connect to my application because the server is sending an invalid response, or can't provide a secure connection.

This isn't usually an issue with Dokku, but rather an app config problem. This can happen when your application is configured to enforce secure connections/HSTS, but you don't have SSL set up for the app.

In Rails at least, if your `application.rb` or `environmnents/production.rb` include the line `configure.force_ssl = true` which includes HSTS, try commenting that out and redeploying.

If this solves the issue temporarily, longer term you should consider [configuring SSL](/docs/configuration/ssl.md).

### My application deploys properly, but won't load in browser "connection refused"

This could be a result of a bad proxy configuration (`http:5000:5000` may be incorrect). Run `dokku proxy:report myapp` to check if your app has the correct proxy configuration. It should show something like the following.

```
=====> myapp proxy information
       Proxy enabled:                 true
       Proxy port map:                http:80:5000 https:443:5000
       Proxy type:                    nginx
```

Set `dokku proxy:ports-set front http:80:5000` to get proxy correctly configured for http endpoint.

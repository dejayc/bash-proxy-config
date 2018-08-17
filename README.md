# bash-proxy-config
**bash-proxy-config**: A script that facilitiates the setting and unsetting
of upstream and local proxies, either for the current shell session, or
individual commands.  Also facilitates the starting of proxies.

## Usage Examples
<a name='Usage Examples'></a>

Specify that the current shell session should use the configured proxy named 
`work` for all non-local network requests:
```
# The following commands are equivalent:
proxy to:work
proxy for:nonlocal to:work
```

Specify that the `curl` command should be executed using the configured
proxy named `work`:
```
proxy to:work curl https://github.com
```

Specify that the current shell session should use the configured proxy named 
`work` for all network requests, including localhost requests:
```
proxy for:all to:work
```

Specify that the current shell session should use no proxy:
```
proxy off
```

Specify that the `curl` command should be executed using the configured
proxy named `local` when retrieving a local web page:
```
proxy to:local curl http://localhost/webpage
```

Specify that the current shell session should use the configured proxy named 
`work` for all non-local network requests, but execute the `curl` command
using no proxy:
```
proxy to:work
proxy off curl https://github.com
```

Start the default proxy command defined by the configured proxy named `work`:
```
proxy listen:work
```

Start the FTP proxy command defined by the configured proxy named `local`:
```
proxy listen:local:ftp
```

Start the HTTP proxy command defined by the configured proxy named `8081`,
and proxy the outbound network calls from the proxy to an upstream configured
proxy named `local`:
```
proxy listen:8081:http to:local
```

## Overview
<a name='Overview'></a>

In Unix-like operating systems, it is common for many programs that initiate
network requests to be capable of doing so using a specified network proxy.
Some of these programs examine the following command-line environment
variables to determine which, if any, proxies to use:

* `HTTP_PROXY` and/or `http_proxy`, for HTTP connections
* `HTTPS_PROXY` and/or `https_proxy`, for HTTPS connections.  If not set,
_some_ programs will instead use variable `HTTP_PROXY`
* `FTP_PROXY` and/or `ftp_proxy`, for FTP connections
* `no_proxy` specifies hosts for which proxies _should not_ be used, e.g.
`"localhost,127.0.0.0/8,[::]"`
 
The purpose of **bash-proxy-config** is to provide commands to easily set,
unset, and modify these proxy variables, either for the current shell session,
or individual commands.  This is useful when working in: corporate
environments, where upstream corporate proxies are common, and; development
environments, where local proxies might be used by developers to capture and
debug local network requests, and; corporate development environments, where
local proxies might forward network requests to upstream corporate proxies.

**bash-proxy-config** also provides additional functionality to start proxy
commands associated with defined proxy configurations.  This is handy for
developers; it is convenient to start a local proxy using the same
configuration being used to route network requests to that proxy.

## Known Limitations
<a name='Known Limitations'></a>

The use of proxy environment variables provides no way to conditionally
direct some network requests to one proxy, while directing other network
requests to another proxy.

Similarly, while the `no_proxy` environment variable allows the ability to
specify certain hosts for which network requests _should not_ be proxied,
there is no ability to do the inverse; i.e. specify that _only_ certain hosts
should be proxied.  Thus, **bash-proxy-config** supports `all` and `nonlocal`
as valid values for the `for:` parameter, but does not support `local`,
because that would not be feasible to implement via `no_proxy`.

Furthermore, `no_proxy` support across programs varies significantly; some
programs allow wildcards and CIDR hosts to be specified in `no_proxy`, while
other programs only support suffix substring matching.

## Design Philosophy
<a name='Design Philosophy'></a>

`bash-proxy-config` is designed around the following principles:

* **User configurability**.  Proxy configurations are defined in separate,
user-controlled files.
* **Configuration flexibility**.  A proxy configuration file is a Bash
script that defines specific variables.  Bash scripts can implement logic as
simple or as sophisticated as necessary to define these variables.
Futhermore, proxy configurations support inheritance of default values from
other proxy configurations, allowing proxy variations to be defined with
minimal redundancy.
* **Configuration freshness**.  Since proxy configurations are reloaded
during every invocation of `bash-proxy-config`, the Bash scripts that define
proxy configurations can dynamically respond to changing network conditions,
or other system status information, to determine appropriate proxy settings.
* **Minimal environmental noise**.  `bash-proxy-config` expends noticeable
effort to minimize the amount of variables and functions that get exposed to
the parent shell session, in order to prevent the implementation details of
`bash-proxy-config` from polluting the environment.

## Installation
<a name='Installation'></a>

### Getting the Source Code
<a name='Getting the Source Code'></a>

`bash-proxy-config` is available via GitHub via the following methods:

**Download the Latest Release:**

https://github.com/dejayc/bash-proxy-config/archive/v1.1.0.zip

https://github.com/dejayc/bash-proxy-config/archive/v1.1.0.tar.gz

**Browse the Latest Release:**

https://github.com/dejayc/bash-proxy-config/releases/tag/v1.1.0

**Git Clone:**
```
git clone https://github.com/dejayc/bash-proxy-config
```

### Installing the Source Code
<a name='Installing the Source Code'></a>

`bash-proxy-config` files can be copied to any directory that is accessible
by the user.

A typical user installation of `bash-proxy-config` consists of the following
steps:

1. Create a new subdirectory `.bash-proxy-config` within the user's `${HOME}`
directory
1. Copy the following project file and subdirectory into
   `.bash-proxy-config`:

   `config.sh`\
   `include/`

1. Update the user's `.bashrc` file to `source` either of the following
   files:

   `.bash-proxy-config/include/alias.sh`, which defines a new _alias_ named
   `proxy`:
   ```
   source "${HOME}/.bash-proxy-config/include/alias.sh"
   ```
   Note that aliases do not appear in the output of the `set` command.

   OR:

   `.bash-proxy-config/include/fn.sh`, which defines a new _function_ named
   `proxy`:
   ```
   source "${HOME}/.bash-proxy-config/include/fn.sh"
   ```

1. If a configuration file other than `${HOME}/.bash-proxy-config/config.sh`
   is to be used, specify the proper location by prefixing the `source`
   command with a variable assignment in the form of:
   ```
   BASH_PROXY_CONFIG='/path/to/bash-proxy-config/config.sh'
   ```
   For example, to load an instance of `bash-proxy-config` that has been
   installed to the directory `/var/bash-proxy-config/`, insert the following
   statement into `.bashrc`:
   ```
   BASH_PROXY_CONFIG='/var/bash-proxy-config/config.sh' \
     source '/var/bash-proxy-config/include/alias.sh'

   ```
   (Note the backslash `\` line continuation character above.)

## Configuration of Proxies
<a name='Configuration of Proxies'></a>

**bash-proxy-config** uses variables within the specified configuration
script (normally `.bash-config-proxy/config.sh`) to configure proxy settings.
Users should customize these variables as appropriate to their environment.

When installed typically, `config.sh` is read during each invocation of
`bash-config-proxy`, in order to ensure configuration freshness, and reduce
pollution of internal environment variables and functions into the parent
session.

### Creating a Proxy Configuration
<a name='Creating a Proxy Configuration'></a>

#### Proxy Configuration Names
<a name='Proxy Configuration Names'></a>

Proxy configurations must be named by the user so they can be referenced from
`bash-proxy-config` commands.  In the following example, proxy configuration
`local` is referenced:

```
proxy to:local
```

Configuration names may contain lowercase letters `a` through `z`, and
numbers `0` through `9`.  No other characters are permitted.

Typical configuration names include `local`, `corp`, `upstream`, etc.  Since
all-numeric names are allowed, names such as `8080` can be used to identify
local proxies on specific ports.

#### Proxy Configuration Variables
<a name='Proxy Configuration Variables'></a>

To create a proxy configuration that can be invoked by `bash-proxy-config`,
create script variables within `config.sh` with names that adhere to the
following convention:

`PROXY_{{NAME}}_{{SETTING}}`

`{{NAME}}` consists of the proxy configuration name, converted to uppercase.

`{{SETTING}}` may consist of any of the following settings: `DEFAULT`, `FOR`,
`FTP_URL`, `HTTP_URL`, `HTTPS_URL`, `NO_PROXY`, or `URL`.

(NOTE: also see the section
[Proxy Startup Variables](#Proxy%20Startup%20Variables) for additional
settings.)

For example, to define a proxy configuration named `local` with a proxy URL
of `http://localhost:8080`, define the following variable within `config.sh`:
```
PROXY_LOCAL_URL='http://localhost:8080'
```

Once any such variable has been defined for a proxy configuration, that
configuration may be invoked using `bash-proxy-config`.

#### Proxy Configuration Default Values
<a name='Proxy Configuration Default Values'></a>

Proxy configurations can easily extend other proxy configurations, to reduce
the need for copying and pasting values between configurations.

For example, to create a proxy configuration named `debug` that is identical
to proxy configuration `local`, define the following variable:

```
PROXY_DEBUG_DEFAULT='local'
```

This assignment causes `bash-proxy-config` to use the proxy configuration
settings of `local` whenever settings for `debug` are undefined.

If proxy configuration `debug` needs a specific setting to differ from that
of `local`, the new setting (e.g. 'NO_PROXY') can be specified:

```
PROXY_DEBUG_DEFAULT='local'
PROXY_DEBUG_NO_PROXY='debug.localhost'
```

All other values for `debug` will continue to derive from `local`.

#### Description of Proxy Configuration Variables
<a name='Description of Proxy Configuration Variables'></a>

<table>
<tr><th>Variable Name</th><th>Purpose</th></tr>
<tr>
<td><a name='PROXY_DEFAULT_TO'></a><code>PROXY_DEFAULT_TO</code></td>
<td><p>The default value to use when the <code>to:</code> parameter is not
specified during a <code>bash-proxy-config</code> command.</p>
<p>The value for this setting should be the lowercase name of a proxy
configuration.</p></td>
</tr>
<tr>
<td><a name='PROXY_NAME_DEFAULT'></a><code>PROXY_{{NAME}}_DEFAULT</code></td>
<td><p>Specifies the proxy configuration to be used to look up default values
when a setting is not defined in the proxy configuration for
<code>{{NAME}}</code>.  Proxy configurations can inherit default values from
other proxy configurations in this manner.</p>
<p>The value for this setting should be the lowercase name of a proxy
configuration.</p></td>
</tr>
<tr>
<td><a name='PROXY_NAME_FOR'></a><code>PROXY_{{NAME}}_FOR</code></td>
<td><p>Specifies the default value of the <code>for:</code> parameter for
proxy configuration <code>{{NAME}}</code>.  This parameter controls the type
of network requests that are sent to the proxy.</p>
<p>Valid values are: <code>all</code>, which represents all network requests;
and <code>nonlocal</code>, which represents all network requests
<em>except</em> for localhost network requests.</p>
<p>If not defined, defaults to the value specified in
<code>PROXY_{{DEFAULT}}_FOR</code>, where <code>{{DEFAULT}}</code> is defined
by <code>PROXY_{{NAME}}_DEFAULT</code>.</p></td>
</tr>
<tr>
<td><a name='PROXY_NAME_FTP_URL'></a><code>PROXY_{{NAME}}_FTP_URL</code></td>
<td><p>Specifies the proxy URL to use for FTP connections when using proxy
configuration <code>{{NAME}}</code>.</p>
<p>If not defined, defaults to the value specified first in:
<ul>
<li><code>PROXY_{{NAME}}_URL</code></li>
<li><code>PROXY_{{DEFAULT}}_FTP_URL</code></li>
<li><code>PROXY_{{DEFAULT}}_URL</code></li>
</ul>
where <code>{{DEFAULT}}</code> is defined by
<code>PROXY_{{NAME}}_DEFAULT</code>.</p></td>
</tr>
<tr>
<td><a name='PROXY_NAME_HTTP_URL'></a>
  <code>PROXY_{{NAME}}_HTTP_URL</code></td>
<td><p>Specifies the proxy URL to use for HTTP connections when using proxy
configuration <code>{{NAME}}</code>.</p>
<p>If not defined, defaults to the value specified first in:
<ul>
<li><code>PROXY_{{NAME}}_URL</code></li>
<li><code>PROXY_{{DEFAULT}}_HTTP_URL</code></li>
<li><code>PROXY_{{DEFAULT}}_URL</code></li>
</ul>
where <code>{{DEFAULT}}</code> is defined by
<code>PROXY_{{NAME}}_DEFAULT</code>.</p></td>
</tr>
<tr>
<td><a name='PROXY_NAME_HTTPS_URL'></a>
  <code>PROXY_{{NAME}}_HTTPS_URL</code></td>
<td><p>Specifies the proxy URL to use for HTTPS connections when using proxy
configuration <code>{{NAME}}</code>.</p>
<p>If not defined, defaults to the value specified first in:
<ul>
<li><code>PROXY_{{NAME}}_URL</code></li>
<li><code>PROXY_{{DEFAULT}}_HTTPS_URL</code></li>
<li><code>PROXY_{{DEFAULT}}_URL</code></li>
</ul>
where <code>{{DEFAULT}}</code> is defined by
<code>PROXY_{{NAME}}_DEFAULT</code>.</p></td>
</tr>
<tr>
<td><a name='PROXY_NAME_NO_PROXY'></a>
  <code>PROXY_{{NAME}}_NO_PROXY</code></td>
<td><p>Specifies the hosts to <em>not</em> proxy network requests to when
using proxy configuration <code>{{NAME}}</code>, when parameter
<code>for:</code> has the value <code>nonlocal</code>.  The value of this
variable is passed to commands via environment variable
<code>no_proxy</code>; each command may interpret that variable
differently.</p>
<p>If not defined, defaults to the value specified in
<code>PROXY_{{DEFAULT}}_NO_PROXY</code>, where <code>{{DEFAULT}}</code> is
defined by <code>PROXY_{{NAME}}_DEFAULT</code>.</p></td>
</tr>
<tr>
<td><a name='PROXY_NAME_URL'></a>
  <code>PROXY_{{NAME}}_URL</code></td>
<td><p>Specifies the proxy URL to use for FTP, HTTP, and HTTPS connections
when using proxy configuration <code>{{NAME}}</code>, when the following
variables are not defined:
<ul>
<li><code>PROXY_{{NAME}}_FTP_URL</code></li>
<li><code>PROXY_{{NAME}}_HTTP_URL</code></li>
<li><code>PROXY_{{NAME}}_HTTPS_URL</code></li>
</ul>
</p>
<p>If not defined, defaults to the value specified in
<code>PROXY_{{DEFAULT}}_URL</code>, where <code>{{DEFAULT}}</code> is defined
by <code>PROXY_{{NAME}}_DEFAULT</code>.</p></td>
</tr>
</table>

#### Proxy Startup Variables
<a name='Proxy Startup Variables'></a>

In addition to the variables that define proxy configurations, additional
variables may be specified to allow proxies to be started on demand, via the
`listen:` parameter, invoked as such:

```
proxy listen:8081
```

Or, to explicitly specify that the FTP proxy (and not the HTTP proxy) should
be started, invoke:

```
proxy listen:8081:ftp
```

To specify that the FTP proxy should be started, with its outbound network
connections themselves being proxied to a different proxy named `company`,
invoke:

```
proxy listen:8081:ftp to:company
```

These additional variables follow the same naming convention as other proxy
configuration variables:

`PROXY_{{NAME}}_{{SETTING}}`

`{{NAME}}` consists of the proxy configuration name, converted to uppercase.

`{{SETTING}}` may consist of any of the following settings: `FTP_LISTEN`,
`FTP_LISTEN_TO`, `HTTP_LISTEN`, `HTTP_LISTEN_TO`, `HTTPS_LISTEN`,
`HTTPS_LISTEN_TO`, `LISTEN`, `LISTEN_TO`.

The value of these settings must define the system command to be executed in
order to start the proxy.  For example, to specify that the `ncat` command
should be executed when starting the HTTP proxy for the configuration named
`local`, specify:

```
PROXY_LOCAL_HTTP_LISTEN='ncat'
```

The `LISTEN` parameter (without protocol prefix) is used as the default
command when no protocol-specific variable has been defined.

The `_TO` variation of the variable is used when the `to:` parameter is
specified when starting the proxy.  For the following example startup command:

```
proxy listen:8081:ftp to:company
```

the following variables would be checked in this order:

* `PROXY_8081_FTP_LISTEN_TO`
* `PROXY_8081_LISTEN_TO`
* `PROXY_8081_FTP_LISTEN`
* `PROXY_8081_LISTEN`

Each of these variables support the special placeholder `{{PROXY}}`, which is
a literal text placeholder to be replaced with the proxy definition specified
by the `to:` parameter, if present.  For example, for the following setting:

```
PROXY_LOCAL_LISTEN_TO='ncat --proxy {{PROXY}}'
```

invoking the following command:

```
proxy listen:local:http to:8081
```

would cause the following command to be executed:

```
ncat --proxy http://localhost:8081/
```

assuming that `PROXY_8081_HTTP_URL` or `PROXY_8081_URL` were defined as
`http://localhost:8081/`.

### Verifying Proxy Settings
<a name='Verifying Proxy Settings'></a>

To verify the settings that `bash-proxy-config` applies, execute the
`proxy-show` and `proxy-settings` commands to see which variables and
settings are applied by `bash-proxy-config`.

For example, to see what environment variables are applied by
`bash-proxy-config` for proxy configuration `local`, execute:
```
proxy to:local proxy-show
```

To see what internal settings (include applied default values) have been
calculated by `bash-proxy-config` for _all_ proxy configurations, execute:
```
proxy proxy-settings
```

Note that `proxy-settings` shows internal settings for _all_ proxy
configurations, even if a specific proxy configuration has been specified via
the `to:` parameter.

## License and Copyright
<a name='License and Copyright'></a>

`bash-proxy-config`: Copyright 2018 by Dejay Clayton, all rights reserved.\
Licensed under the 2-Clause BSD License.
* https://github.com/dejayc/bash-proxy-config
* http://opensource.org/licenses/BSD-2-Clause

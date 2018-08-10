# bash-proxy-config
**bash-proxy-config**: A script that facilitiates the setting and unsetting
of upstream and local proxies, either for the current shell session, or
individual commands.

## Usage Examples
<a name='Usage Examples'></a>

TODO

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

## Known Limitations
<a name='Known Limitations'></a>

The use of proxy environment variables provides no way to conditionally
direct some network requests to one proxy, while directing other network
requests to another proxy.

Similarly, while the `no_proxy` environment variable allows the ability to
specify certain hosts for which network requests _should not_ be proxied,
there is no ability to do the inverse; i.e. specify that _only_ certain hosts
should be proxied.

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

https://github.com/dejayc/bash-proxy-config/archive/v1.0.0.zip

https://github.com/dejayc/bash-proxy-config/archive/v1.0.0.tar.gz

**Browse the Latest Release:**

https://github.com/dejayc/bash-proxy-config/releases/tag/v1.0.0

**Git Clone:**
```
git clone https://github.com/dejayc/bash-proxy-config
```

### Installing the Source Code
<a name='Installing the Source Code'></a>

TODO

## Configuration of Proxies
<a name='Configuration of Proxies'></a>

**bash-proxy-config** uses variables within the specified configuration
script (normally `.bash-config-proxy/config.sh`) to configure proxy settings.
Users should customize these variables as appropriate to their environment.

### Creating a Proxy Configuration
<a name='Creating a Proxy Configuration'></a>

#### Proxy Configuration Names
<a name='Proxy Configuration Names'></a>

Proxy configurations must be named by the user so they can be referenced from
`bash-proxy-config` commands.

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

`{{SETTING}}` may consist of any of the following settings: `NO_PROXY`, or
`URL`.

For example, to define a proxy configuration named `local` with a proxy URL
of `http://localhost:8080`, define the following variable within `config.sh`:
```
PROXY_LOCAL_URL='http://localhost:8080'
```

Once any such variable has been defined for a proxy configuration, that
configuration may be invoked using `bash-proxy-config`.

#### Description of Proxy Configuration Variables
<a name='Description of Proxy Configuration Variables'></a>

<table>
<tr><th>Variable Name</th><th>Purpose</th></tr>
<tr>
<td><a name='PROXY_NAME_NO_PROXY'></a>
  <code>PROXY_{{NAME}}_NO_PROXY</code></td>
<td><p>Specifies the hosts to <em>not</em> proxy network requests to when
using proxy configuration <code>{{NAME}}</code>.  The value of this variable
is passed to commands via environment variable <code>no_proxy</code>; each
command may interpret that variable differently.</p></td>
</tr>
<tr>
<td><a name='PROXY_NAME_URL'></a>
  <code>PROXY_{{NAME}}_URL</code></td>
<td><p>Specifies the proxy URL to use for FTP, HTTP, and HTTPS connections
when using proxy configuration <code>{{NAME}}</code>.</p></td>
</tr>
</table>

## License and Copyright
<a name='License and Copyright'></a>

`bash-proxy-config`: Copyright 2018 by Dejay Clayton, all rights reserved.\
Licensed under the 2-Clause BSD License.
* https://github.com/dejayc/bash-proxy-config
* http://opensource.org/licenses/BSD-2-Clause

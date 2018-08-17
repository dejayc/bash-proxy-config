#!/bin/bash
PROXY_DEFAULT_TO='default'

# Proxy default fallbacks
PROXY_DEFAULT_FOR='nonlocal'
PROXY_DEFAULT_URL='http://proxy.example.com/'
PROXY_DEFAULT_FTP_URL='ftp://proxy.example.com/'
PROXY_DEFAULT_HTTP_URL=''
PROXY_DEFAULT_HTTPS_URL=''
PROXY_DEFAULT_NO_PROXY='localhost,127.0.0.0/8,[::]'

# Proxy configuration named 'local'
PROXY_LOCAL_FOR='nonlocal'
PROXY_LOCAL_DEFAULT=''
PROXY_LOCAL_URL='http://localhost:8080/'
PROXY_LOCAL_LISTEN='mitmproxy -p 8080'
PROXY_LOCAL_LISTEN_TO='mitmproxy -p 8080 --mode=upstream:{{PROXY_TO}}'

# Proxy configuration named '8081'
PROXY_8081_FOR='all'
PROXY_8081_DEFAULT='local'
PROXY_8081_URL='http://localhost:8081/'
PROXY_8081_FTP_LISTEN='ncat -l 8081'
PROXY_8081_FTP_LISTEN_TO='ncat -l 8081 --proxy {{PROXY_TO}}'
PROXY_8081_HTTPS_LISTEN='ncat -l 443'

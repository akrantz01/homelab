# Custom NginX

This is used to build a custom version of NginX with more modern features enabled.

### Features
- [HTTP/3](https://blog.cloudflare.com/http3-the-past-present-and-future/) (QUIC) via [Cloudflare's quiche](https://github.com/cloudflare/quiche)
- HTTP/2
- [BoringSSL](https://github.com/google/boringssl) instead of OpenSSL
- TLS 1.3 with 0-RTT support
- [HPACK](https://blog.cloudflare.com/hpack-the-silent-killer-feature-of-http-2/)
- Brotli compression
- [headers-more-nginx-module](https://github.com/openresty/headers-more-nginx-module)
- [NJS](https://www.nginx.com/blog/introduction-nginscript/)
- [nginx_cookie_flag_module](https://www.nginx.com/products/nginx/modules/cookie-flag/)
- PCRE latest with [JIT compilation](http://nginx.org/en/docs/ngx_core_module.html#pcre_jit) enabled
- zlib latest

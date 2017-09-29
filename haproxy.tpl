global
    maxconn {{keyOrDefault "service/haproxy/maxconn" "256"}}
    debug
    # Recommended SSL ciphers as per https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
    ssl-default-bind-options no-sslv3
    ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS

    ssl-default-server-options no-sslv3
    ssl-default-server-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS
    tune.ssl.default-dh-param 2048

defaults
    mode http
    option forwardfor
    option http-server-close
    timeout connect {{keyOrDefault "service/haproxy/timeouts/connect" "5000ms"}}
    timeout client {{keyOrDefault "service/haproxy/timeouts/client" "50000ms"}}
    timeout server {{keyOrDefault "service/haproxy/timeouts/server" "50000ms"}}

### HTTP(S) frontend ###
frontend www
    bind *:80
    {{ if env "HAPROXY_USESSL" }}bind *:443 ssl crt /haproxy/ssl.crt{{ end }}

    reqadd X-Forwarded-Proto:\ http if !{ ssl_fc }
    reqadd X-Forwarded-Proto:\ https if { ssl_fc }
    {{ if eq (env "HAPROXY_USESSL") "force" }}
    # Redirect all non-secure connections to HTTPS
    redirect scheme https if !{ ssl_fc }{{ end }}

    # Generated automatically by consul-template
{{ range services }}{{if .Tags | contains  "web" }}
    acl {{.Name}}_context path_beg /{{.Name}}
    reqrep ^([^\ ]*)\ /web1/(.*)     \1\ /\2
    use_backend {{.Name}}_backend if {{.Name}}_context
#    acl host_{{ .Name }} hdr_beg(host) -i {{ .Name }}.{{ or (env "HAPROXY_DOMAIN") "haproxy.service.consul" }}
#    use_backend {{ .Name }}_backend if host_{{ .Name }}
{{ end }}{{ end }}

{{ if env "HAPROXY_STATS" }}
frontend stats
    bind *:1936
    mode http
    use_backend stats
{{ end }}


### Consul-configured backend services ###
{{ range services }}{{if .Tags | contains  "web" }}
backend {{ .Name }}_backend
{{ range service .Name }}
   server {{ .Node }}-{{ .Port }} {{ .Address }}:{{ .Port }}{{ end }}
{{ end }}{{ end }}

{{ if env "HAPROXY_STATS" }}

backend stats
    stats enable
    stats hide-version
    stats refresh 5s
    stats scope .
    stats realm {{ or (env "HAPROXY_STATS_TITLE") "Haproxy Statistics" }}
    stats uri {{ or (env "HAPROXY_STATS_URI") "/" }}
{{ end }}
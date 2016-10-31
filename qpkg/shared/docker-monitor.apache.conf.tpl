ProxyPass /docker-monitor/ !
RedirectMatch 301 ^/docker-monitor/(.*)$ http://{{IPV4ADDR}}:3000/$1

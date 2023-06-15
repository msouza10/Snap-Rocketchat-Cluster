#!/bin/bash

function check_command() {
    command -v $1 >/dev/null 2>&1
}

function check_package() {
    dpkg -s $1 >/dev/null 2>&1
}

function install_package() {
    local package=$1
    if check_package "$package"; then
        echo "$package já está instalado."
    else
        echo "Instalando $package..."
        sudo apt-get -y install "$package"
        echo "Instalação de $package concluída."
    fi
}

if ! check_command sudo; then
    echo "Erro: 'sudo' não encontrado. Este script deve ser executado com privilégios de sudo."
    exit 1
fi

install_package haproxy

sudo snap set system experimental.parallel-instances=true
if [ $? -ne 0 ]; then
    echo "Falha ao definir instâncias paralelas."
    exit 1
fi

sudo snap install rocketchat-server_cluster1
if [ $? -ne 0 ]; then
    echo "Falha ao instalar rocketchat-server_cluster1."
    exit 1
fi

snap stop rocketchat-server_cluster1.rocketchat-mongo
if [ $? -ne 0 ]; then
    echo "Falha ao parar rocketchat-server_cluster1.rocketchat-mongo."
    exit 1
fi

sudo snap install rocketchat-server_cluster2
if [ $? -ne 0 ]; then
    echo "Falha ao instalar rocketchat-server_cluster2."
    exit 1
fi

snap start rocketchat-server_cluster1.rocketchat-mongo
if [ $? -ne 0 ]; then
    echo "Falha ao iniciar rocketchat-server_cluster1.rocketchat-mongo."
    exit 1
fi

sudo snap set rocketchat-server_cluster1 port=3001
if [ $? -ne 0 ]; then
    echo "Falha ao definir a porta de rocketchat-server_cluster1."
    exit 1
fi

sudo snap set rocketchat-server_cluster2 port=3002
if [ $? -ne 0 ]; then
    echo "Falha ao definir a porta de rocketchat-server_cluster2."
    exit 1
fi

cat > /etc/haproxy/haproxy.cfg  << EOF

global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-G>
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option http-keep-alive
    timeout connect 3000
    timeout client  30000
    timeout server  30000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend http_front
    bind *:80
    default_backend http_back

backend http_back
    balance roundrobin
    option httpchk GET /health
    server rocketchat_cluster1 localhost:3001 check
    server rocketchat_cluster2 localhost:3002 check 
EOF

service haproxy restart
if [ $? -ne 0 ]; then
    echo "Falha ao inicia o HAproxy"
    exit 1
fi

# Lista de portas para verificar
ports=(3001 3002 80)

# Loop através das portas
for port in ${ports[@]}; do
    # Tenta fazer uma solicitação para a porta
    curl -f http://localhost:$port

    # Se a solicitação falhar, imprime uma mensagem e sai do script
    if [ $? -ne 0 ]; then
        echo "O serviço na porta $port não está respondendo"
        exit 1
    fi
done

# Se todas as portas responderem, imprime uma mensagem de sucesso
echo "Todos os serviços estão respondendo, cluster UP"
exit 0

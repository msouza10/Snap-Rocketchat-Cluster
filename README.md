# 🚀 Instalação e Configuração do Rocket.Chat com HAProxy

Este script automatiza o processo de instalação e configuração do Rocket.Chat com o HAProxy para balanceamento de carga. Ele instala o HAProxy, configura duas instâncias paralelas do Rocket.Chat (clusters), e configura o HAProxy para balancear o tráfego entre esses dois clusters.

Ao utilizar este script, você estará preparando seu ambiente para uma alta disponibilidade, permitindo que suas instâncias do Rocket.Chat operem simultaneamente e compartilhem a carga de trabalho.

## 📋 Pré-requisitos

- Uma máquina rodando Ubuntu 20.04 ou superior.
- Privilégios de superusuário (root).
- Conexão com a internet.

## 🔧 Como Usar

1. Faça o download do script para a sua máquina.

2. Dê ao script permissões de execução usando o comando: `chmod +x script.sh`.

3. Execute o script como superusuário (root) com o comando: `sudo ./script.sh`.

4. O script irá instalar e configurar todos os componentes necessários. Ele irá parar e exibir uma mensagem de erro se encontrar algum problema.

5. Se tudo for instalado e configurado com sucesso, o script imprimirá uma mensagem de sucesso no final: "Todos os serviços estão respondendo, cluster UP".

## ⚠️ Notas

Este script é apenas para fins de teste e não deve ser usado em ambientes de produção sem a devida verificação e ajustes conforme as necessidades do ambiente.

## 🤝 Contribuições

Contribuições e sugestões são bem-vindas através de Pull Requests e Issues.

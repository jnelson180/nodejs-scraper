FROM ubuntu:16.04
MAINTAINER Manuel Jiménez Bernal <manu.asi2@gmail.com>

# instalar paquetes
RUN apt-get update && apt-get install -y curl git build-essential nano
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app/
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash

RUN git clone https://github.com/manuasir/NodeJS-WebCrawler.git

WORKDIR /usr/src/app/NodeJS-WebCrawler/
#versión de Node
ENV NODE_VERSION 8.7.0

#necesario para nvm
ENV NVM_DIR /root/.nvm

#abre el puerto 3000
EXPOSE 3000

#arranca el script que lo hace casi todo
CMD ["/root/.nvm/version/8.7.0/node/bin/npm", "start"]

# Documentación ProyectoIV
Proyecto para la asignatura Infraestructura Virtual de la Universidad de Granada 

#### Web-Crawler

Extrae y organiza hipervínculos por niveles a partir de una URL de origen resultando en una estructura de árbol almacenada en una base de datos MongoDB, presentándose en una interfaz web o mediante peticiones REST. Este proyecto utiliza el stack de Javascript MEAN: (MongoDB + Express + AngularJS + NodeJS).

[Artículo wikipedia aquí](https://en.wikipedia.org/wiki/Web_crawler)

#### Planteamiento

Se trata construir una estructura de datos de tipo árbol en la que se van a organizar las URL extraídas.
El backend corriendo bajo Node.JS se encarga de gestionar este almacenamiento construyendo objetos JSON que respeten la estructura de árbol inicial, y la almacene en una base de datos documental MongoDB.
También se gestionan las peticiones mediante la implementación de una REST API sobre Express, el cual proporcionará los datos al cliente AngularJS, que muestra la información en la interfaz web.

Se debe elegir el nivel de profundidad hasta el cual se va a explorar el árbol, aumentando exponencialmente los recursos requeridos para ejecutar la aplicación.


#### Uso e Integración Continua con Travis-CI:
Es necesario tener el servicio mongod activo
> $ node /app/server.js
> Comienza a recibir peticiones a través de http://localhost:3000

Se utilizó Travis-CI para la Integración Continua al ofrecer ventajas tales como trabajar con repositorios privados al ser beneficiario de GitHub Students.

#### Despliegue en Heroku

Como servicio PaaS se eligió Heroku al contar previamente con una cuenta en la plataforma. Las gestiones se realizaron desde el dashboard que ofrece el servicio, facilitando el proceso.
En primer lugar se creó la nueva aplicación vacía bajo el stack de Node.JS, siendo linkada con el repositorio en GitHub donde se encuentra el código y los scripts necesarios para automatizar el proceso de despliegue. 

![](http://i1339.photobucket.com/albums/o717/manuasir/c1_zpse7unryds.png)

Como lo que se pretende es que se haga el deploy una vez se pasen los tests, hay que activar la opción pertinente en el panel de administración. Para ello Heroku detecta automáticamente el servicio Travis-CI de integración continua que realiza los tests de la aplicación. En el caso de que los tests fallen, la aplicación no se desplegará.
![](http://i1339.photobucket.com/albums/o717/manuasir/c2_zpspobplvzw.png)
Se ha de elegir la rama que se pretende que se despliegue al realizar push, en este caso la rama 'master'. 
Una vez realizados éstos pasos se procede a lanzar el deploy desde el push a nuestro repositorio. Se ha de generar automáticamente un fichero [app.json](https://github.com/manuasir/ProyectoIV/blob/master/app.json) en el raíz del proyecto con información sobre el esquema de la aplicación.
Una vez realizado el deploy con éxito, lanzamos la aplicación desde el navegador en la URL correspondiente. Es en este momento cuando aparecen los errores en tiempo de ejecución, para este caso relacionados con las conexiones a la base de datos MongoDB, que seguían intentando conectar en 'localhost'.
La solución es instalar los plugins necesarios que resuelvan estas dependencias. En este proyecto se instaló el plugin de MongoLAB, el cual cuenta con un sandbox de prueba gratuita para crear y administrar nuestros documentos y colecciones.
![](http://i1339.photobucket.com/albums/o717/manuasir/c3_zpsrvlhznte.png)
Cambiamos en la aplicación las conexiones para que apunten al nuevo servidor de MongoDB y el problema quedó resuelto. 
Paralelamente es necesario instalar las dependencias necesarias post-deploy. 
En este proyecto se utilizó el gestor de dependencias para front-end 'bower', por lo que desde el fichero [package.json](https://github.com/manuasir/ProyectoIV/blob/master/package.json) en el campo 'scripts' se hubo que asegurar que se realizaba la instalación de las dependencias bower necesarias como AngularJS, Bootstrap y otras librerías.
Se puede acceder al proyecto en producción [aquí](https://ivwebcrawler.herokuapp.com/).

#### Docker

Se va a aislar la aplicación en un contenedor Docker,por lo que hay que generar un fichero Dockerfile en el que se incluirán las secuencias de comandos necesarias para el despliegue de la aplicación.

A continuación procede generar una imagen de nuestro contenedor mediante el servicio docker-hub, al cual enlazaremos nuestra cuenta de github para que la plataforma pueda sincronizar con los repositorios.
Desde la seccion 'Create Automated Build' seleccionamos nuestra cuenta de github como origen y escogemos el repositorio que nos interesa desplegar
![](http://s1339.photobucket.com/user/manuasir/media/hub1_zpsytocinpn.png.html" target="_blank"><img src="http://i1339.photobucket.com/albums/o717/manuasir/hub1_zpsytocinpn.png" border="0" alt=" photo hub1_zpsytocinpn.png)

Los parámetros mediante los cuales se construirá la imagen estarán determinados por el fichero Dockerfile, desde el cual se deberán instalar los paquetes necesarios para la ejecución

```c
FROM ubuntu:14.04
MAINTAINER Manuel Jiménez Bernal <manuasir@correo.ugr.es>

# instalar paquetes
RUN apt-get update && apt-get install -y curl git build-essential
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app/
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash
RUN git clone https://github.com/manuasir/ProyectoIV.git
WORKDIR /usr/src/app/ProyectoIV/
#versión de Node
ENV NODE_VERSION 4.6.1

#necesario para la instalación de NVM
ENV NVM_DIR /root/.nvm

#clonar repositorio

#instalar la versión de node y seleccionar como predeterminada. también se instalan paquetes globales (-g)
RUN . ~/.nvm/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && npm install -g bower pm2 gulp grunt
# Añadir script que automatiza el despliegue
ADD ./deploy.sh /deploy.sh

#abre el puerto 3000
EXPOSE 3000

#arranca el script que lo hace casi todo
CMD ["/bin/bash", "/deploy.sh"]
```

Se programó un script para automatizar el proceso de instalación de librerías y dependencias necesarias de Node.JS que se utilizan en el proyecto

```c
#! /bin/bash

if [ -z "$APP_MAIN" ]; then APP_MAIN="bin/www"; fi;

echo NodeJS app\'s start en: $APP_MAIN

#comprueba y cambia la hora. necesario si se exporta en IaaS
if [ -n "$TIME_ZONE" ]
then
  echo $TIME_ZONE | sudo tee /etc/timezone;
  sudo dpkg-reconfigure -f noninteractive tzdata;
fi

#instala versión de node,pone permisos pertinentes, instala librerías
. ~/.nvm/nvm.sh && nvm use 4.6.1; \
  npm install && bower install --allow-root && grunt && gulp compress; \
NODE_ENV=production npm start
```
Este script se ejecuta en el momento de arrancar la imagen (docker run), y entre las tareas mencionadas previamente, el script se encarga también de generar los ficheros minificados y las inyecciones de dependencias por gulp y la documentación generada por grunt.
Èn cuanto se hizo el push a la rama master, se creó una imagen en [docker-hub](https://hub.docker.com/r/manuasir/proyectoiv/) disponible para que pueda desplegarse
desde cualquier entorno que cuente con docker.
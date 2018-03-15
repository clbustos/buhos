# Buhos

[![Status del paquete](https://travis-ci.org/clbustos/buhos.svg?branch=master)](https://travis-ci.org/clbustos/buhos)
[![Mantenibilidad](https://api.codeclimate.com/v1/badges/ffa582598127f86ed405/maintainability)](https://codeclimate.com/github/clbustos/buhos/maintainability)
[![Cobertura de pruebas](https://api.codeclimate.com/v1/badges/ffa582598127f86ed405/test_coverage)](https://codeclimate.com/github/clbustos/buhos/test_coverage)

Plataforma basada en web para gestionar el proceso completo de revisiones sistemáticas de literatura. Desarrollado usando Sinatra, un DSL  basado en Ruby.


## Características

* Multi-platforma: Corre en Linux(probado en Ubuntu 14.04 y 16.06), Windows (probado en Windows 7 y 10) y MacOS (probado en High Sierra)
* Puede ser usado para realizar revisiones sistemáticas por un individuo o por un grupo de trabajo.
* Sistema de mensajería interna, para mensajes personales o relacionados a las revisiones sistemáticas.
* Multilenguaje, usando *I18n*. Disponible en inglés y español.
* Flujo de trabajo flexible. Las etapas principales de buscar textos, tamizar los artículos pertinentes, extraer información y realizar reportes están claramente definidas. Sin embargo, es posible realizar cambios en cualquier etapa ya concluida, afectando las etapas posteriores.
* Importa información desde distintas bases de datos bibliográficas, como - WoS, Scopus, Ebscohost, Scielo - usando BibTeX.
* Integración con Crossref, lo que permite eliminar artículos duplicados (usando DOI), así como buscar información sobre referencias.
* Repositorio de archivos. Se pueden ver en línea archivos PDF y ODF, usando  [ViewerJS](http://viewerjs.org/)
* Múltiples formas de analizar datos: se pueden incorporar comentarios y etiquetas en cada etapa, así como generar formularios personalizados para extraer información.
* Distintos tipos de reporte: se cuenta con reportes para los datos extraídos de los textos, un reporte detallado del proceso de decisión en cada etapa de la revisión, así como un [diaframa de flujo PRISMA](http://prisma-statement.org/prismastatement/flowdiagram.aspx) para resumir el proceso, listo para publicaciones.
* Distintos tipos de archivos para exportar: Se pueden exportar las referencias como BibTeX, así como generar archivos GraphML para realizar análisis de grafos.
* Test unitarios y de integración para los principales recursos del software

## Documentación

Se cuenta con un manual disponible en  [español](https://buhos.org/manual/es/) e [inglés](https://buhos.org/manual/en/), que contiene una guía rápida para entender la metodología de revisión sistemática que sustena el software.

La API está documentada usando [Yard](https://yardoc.org/) y está disponible en [https://www.buhos.org/api](https://www.buhos.org/api). Sólo se encuentra disponible en inglés.

## Comenzar a trabajar

### En Windows

Se puede obtener el instalador de Windows desde  [Buhos Windows Toolkit](https://github.com/clbustos/buhos-windows-tk/tree/master/windows_installer)

### En *nix

Para Debian, Ubuntu y CentOS, se encuentran disponibles paquetes e instrucciones de instalación en  [packager.io](https://packager.io/gh/clbustos/buhos).  Como ejemplo, para instalar en Ubuntu se pueden seguir las siguientes instrucciones, usando localhost:4567 como URL

    wget -qO- https://dl.packager.io/srv/clbustos/buhos/key | sudo apt-key add -
    sudo wget -O /etc/apt/sources.list.d/buhos.list \
      https://dl.packager.io/srv/clbustos/buhos/master/installer/ubuntu/16.04.repo
    sudo apt-get update
    sudo apt-get install buhos
    sudo buhos config:set PORT=4567
    sudo buhos scale web=1
    sudo buhos restart 

### Usar vagrant

En los directorios vendor/vagrant_alpine y vendor/vagrant_ubuntu_16 pueden configuraciones de vagrant para Alpine y Ubuntu 16.04, respectivamente. Se pueden ejecutar usando
    
    > vagrant up
    
De forma predeterminada, la aplicación corre en el puerto 4567.
    
### Usando código fuente (última versión)

#### Requisitos previos


En linux, se necesita una instalación de Ruby 2.4 con bundler, y bibliotecas de desarrollo para mysql y sqlite. Recomendamos usar [RVM](https://rvm.io/).


En Ubuntu, este script instala todas las dependencias


    # Update system
    apt-get update
    apt-get upgrade -y
    
    apt-get install -y \
      cloc \
      gdal-bin \
      gdebi-core \
      git \
      libcurl4-openssl-dev \
      libgdal-dev \
      libproj-dev \
      libxml2-dev \
      ghostscript \
      imagemagick \
      xpdf \
      build-essential \
      libmysqlclient-dev \
      libsqlite3-dev
    
    # Install RVM
    
    gpg --keyserver hkp://keys.gnupg.net \
          --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -sSL https://get.rvm.io | bash -s $1
    
      
En alpine, la configuración básica es

    apk update
    apk upgrade
    apk --update add --virtual \
        build-dependencies \
        ruby-dev \
        build-base \
        ruby \
        libffi-dev \
        libxml2-dev \
        libxslt-dev \
        mariadb-dev \
        sqlite-dev \
        ruby-json \
        ruby-bigdecimal \
        ruby-etc    

Una vez que todas las dependencias han sido instaladas, se puede copiar el código fuente haciendo

   > git clone git@github.com:clbustos/buhos.git

Se instalan las dependencia de Ruby necesarias usando bundler

   > bundle install
   
Y se ejecuta la aplicación corriendo

   > ruby app.rb

## Configuración post-instalación

La aplicación se configura mediante la web. Una vez que el servidor se inicia, se debe apuntar el navegador de forma predeterminada a http://localhost:4567, para iniciar el proceso de instalación.

Si desea utilizar una base de datos MySQL, se debe crear antes de configurar el software. Usando el usuario root de MySQL, las instrucciones serían 

    CREATE DATABASE buhos;
    CREATE USER buhos_user@localhost IDENTIFIED BY 'password';
    GRANT ALL PRIVILEGES ON buhos.* TO buhos_user@localhost;
    FLUSH PRIVILEGES;

Primero, debe definir el lenguaje de instalación. Segundo, debe proveer información acerca de la base de datos específica (sqlite / mysql); de forma predeterminada, se instala una base sqlite en db.sqlite. Si se cuenta con una clave SCOPUS API, se puede entregar la información pertinente, junto con la configuración del proxy, si corresponde. 
Como paso final, se llena la base de datos. Se debe reiniciar la aplicación antes de usarla.

    

## Implementación

Para su uso por individuos, la aplicación puede ejecutarse sin problemas usando el instalador en Windows, o los paquetes para Ubuntu, Debian o CentOS.

Para su uso en línea por múltiples usuarios, se ha probado el uso de Buhos desplegado en un servidor HTTP independiente, usando Passenger como conector con Nginx. Para la base de datos, se ha usado MySQL. En teoría, el software debería funcionar sin problemas en MariaDB y Apache.

Una configuración típica para nginx debería lucir como:
    
    server {
      listen 80
      root /home/<user>/<base_dir>; 
      passenger_enabled on; 
      passenger_ruby <ruby_location> 
    }

El ubicación del ejecturable ruby se puede obtener desde 

    > which ruby

Si se ocupa [RVM](https://rvm.io/) con Passenger, revise [esta página](https://rvm.io/deployment/passenger)


## Construido con 
* [Sinatra](http://sinatrarb.com/) - Sinatra es un DSL para crear aplicaciones web en Ruby con mínimo esfuerzo
* [Sequel](https://github.com/jeremyevans/sequel) - Sequel es un set de herramientas para bases de datos.Provee una capa de abstracción y funcionalidades ORM, entre otras cosas.

* [Bootstrap](https://getbootstrap.com/) -  Bootstrap es un set de herramientas de código abierto para desarrollar HTML, CSS, y JS.
* [jQuery](https://jquery.com/) - jQuery is una librería muy usada para JavaScript.
* [ViewerJS](http://viewerjs.org/) - ViewerJS permite visualizar en línea archivos PDF y ODT.
* [RubyMine](https://www.jetbrains.com/ruby/) - Un muy buen IDE para Ruby

## Cómo contribuir

Si quiere contribuir, envíe un email a clbustos_at_gmail.com. Si quiere enviar un parche, lo ideal es crear una versión (fork) del repositorio en [github](https://github.com/clbustos/buhos) y realizar una petición pull.

## Como se identificar las versiones

Usamos [SemVer](http://semver.org/) para for identificar las versiones. Para ver las versiones disponibles del software, revise los [tags en este repositorio](https://github.com/clbustos/buhos/tags). 

## Autoría

### Desarrolladores

* **Claudio  Bustos** - *Desarrollador principal* - [clbustos](https://github.com/clbustos)

### Contribuciones
* **Daniel Lermanda** - Diseñador de página web y asesoría en experiencia de usuario
* **María Gabriela Morales** - Primera conceptualización y revisión del manual
* **Liz Medina** -  traducción al inglés de página de inicio y manual.
* **Alejandro Díaz, Pedro Salcedo**: Desarrollo de requerimientos de usuarios.

## Licencia

Este proyecto está licenciado para la Licencia BSD de 3 cláusulas - vea el archivo [LICENSE](LICENSE) para mayores detalles.


# Buhos

Web based platform to develop collaborative systematic literatute reviews. Developed usign Sinatra, a Ruby DSL.


## Features

* Multiplatform: Runs on Linux (tested on Ubuntu 14.04 and 16.06) and Windows (tested on Windows 7 and 10)
* Support individual and group based systematic reviews. 
* Messaging system for members and reviews.
* Internationalization, using *I18n*. Available in english and spanish
* Flexible workflow
* Import information from several databases - WoS, Scopus, Scielo - using BibTeX.
* Integration with Crossref, that allows deduplication of records using DOI, recollection of references
* File repository, with PDF viewing support via [ViewerJS](http://viewerjs.org/)
* Multiple ways to analyze data: commentaries and tagging on each stage of review, custom forms for complete text analysis
* Reports: PRISMA flowchart, data extraction of complete text and process report

## Getting Started

### On Windows

A installer for the latest version of software, for Windows, can be obtained from [Buhos Windows Toolkit](https://github.com/clbustos/buhos-windows-tk/tree/master/output)

### On *nix

For Debian, Ubuntu y CentOS, packages and instructions to install are availables on [packager.io](https://packager.io/gh/clbustos/buhos).  As example, this instructions allows to install buhos on Ubuntu, using localhost:4567 as URL

    wget -qO- https://dl.packager.io/srv/clbustos/buhos/key | sudo apt-key add -
    sudo wget -O /etc/apt/sources.list.d/buhos.list \
      https://dl.packager.io/srv/clbustos/buhos/master/installer/ubuntu/16.04.repo
    sudo apt-get update
    sudo apt-get install buhos
    sudo buhos config:set PORT=4567
    sudo buhos scale web=1
    sudo buhos restart 

### Using vagrant

On vendor/vagrant_alpine and vendor/vagrant_ubuntu_16 directories you could find working vagrant configurations for Alpine and Ubuntu 16.04, respectively. You could run it using
    
    > vagrant up
    
By default, the application is configured to run on port 4567. 
    
### Using source code (latest)

#### Prerequisites


On linux, you need a ruby 2.4 installation with bundler, and development libraries for mysql and sqlite. We recommend using [RVM](https://rvm.io/).


On Ubuntu, this script install all required dependencies


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
      libxml2-dev \
      build-essential \
      libmysqlclient-dev \
      libsqlite3-dev
    
    # Install RVM
    
    gpg --keyserver hkp://keys.gnupg.net \
          --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -sSL https://get.rvm.io | bash -s $1
    
      
On alpine, the basic configuration is   

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

Once you have all necesary dependencies , copy the source code using

   > git clone git@github.com:clbustos/buhos.git

Install necessary dependencies using bundler

   > bundle install
   
And run the application using

   > ruby app.rb

## Post-install configuration

The app uses a web-based installer. Once you start the server with you should point your browser to localhost:4567 and the installation process should began.

If you want to use a Mysql database, you should create it before installing the sofware. As mysql root user, you could use something like

    CREATE DATABASES buhos;
    CREATE USER buhos_user@localhost IDENTIFIED BY 'password';
    GRANT ALL PRIVILEGES ON buhos.* TO buhos_user@localhost;
    FLUSH PRIVILEGES;

First, you define the installation language. Second, you should provide information about database support (sqlite / mysql). If you have a SCOPUS API key, you could provide it along proxy settings.
Finnaly, the database will be populated and you should restart the application to start using it.

    

## Deployment

For individual users, the application could be run without problem using the windows installer or the packages for Ubuntu, Debian or CentOS

For multiple users, you should deploy on a web server and a more powerful database. The development is tested on nginx ussing passenger+ Mysql, but should  work on Apache, too.

A typical nginx configurations should look like this:
    
    server {
      listen 80
      root /home/<user>/<base_dir>; 
      passenger_enabled on; 
      passenger_ruby <ruby_location> 
    }
    
Ruby location could be obtained with

    > which ruby

If you using [RVM](https://rvm.io/) with passenger, check [this page](https://rvm.io/deployment/passenger)


## Built With
* [Sinatra](http://sinatrarb.com/) - Sinatra is a DSL for quickly creating web applications in Ruby with minimal effort
* [Sequel](https://github.com/jeremyevans/sequel) - Sequel is a simple, flexible, and powerful SQL database access toolkit for Ruby.
* [Bootstrap](https://getbootstrap.com/) -  Bootstrap is an open source toolkit for developing with HTML, CSS, and JS.
* [jQuery](https://jquery.com/) - jQuery is a fast, small, and feature-rich JavaScript library. 
* [ViewerJS](http://viewerjs.org/) - ViewerJS allows to use presentations, spreadsheets, PDF's and other documents on your website or blog without any external dependencies.
* [RubyMine](https://www.jetbrains.com/ruby/) - A good Ruby IDE

## Contributing

If you want to contribute, just send a email to clbustos_at_gmail.com. If you want to send a patch, the preferred method is fork the repository on [github](https://github.com/clbustos/buhos) and make a pull request.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/clbustos/buhos/tags). 

## Authors

* **Claudio  Bustos** - *Main developer* - [clbustos](https://github.com/clbustos)
* **Daniel Lermanda** - *Web page designer and UX advisor*



## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE.md](LICENSE.md) file for details


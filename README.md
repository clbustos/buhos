# Buhos

Web based platform to develop collaborative systematic reviews and meta-analysis. Developed usign Sinatra, a Ruby DSL.


## Features

* Multiplatform: Runs on Linux and Windows
* Support individual and group based systematic reviews. 
* Messaging system for members and reviews.
* Internationalization, using *I18n*. Available in english and spanish
* Flexible workflow
* Import information from several databases - WoS, Scopus, Scielo - using BibteX and CSV.
* Integration with Crossref, that allows deduplication of records using DOI, recollection of references
* File repository, with PDF viewing support
* Multiple ways to analyze data: commentaries and tagging on each stage of review, custom forms for complete text analysis
* Multiple outputs.

## Getting Started

### Using source code (latest)

You need a ruby 2.2 or later installed, and bundler gem. To install mysql and sqlite gems, development libraries should be installed.
 
Copy the source code using

   > git clone git@github.com:clbustos/buhos.git

Install necessary dependencies using bundler

   > bundle install
   
And run the application using

   > ruby app.rb

### Using portable installer

A portable version of software, for Windows, can be obtained from https://www.buhos.org/

### Using vagrant

On vendor/vagrant directory you could find a working vagrant configuration. You could run it using
    
    > vagrant up
    
By default, the application is configured to run on port 4567.    

### Prerequisites


On linux, you need a ruby 2.2 installation with bundler, and development libraries for mysql and sqlite. We recommend using [RVM](https://rvm.io/).

A script on Ubuntu 16.06 that install RVM and system dependencies is:

    # Install RVM
    gpg --keyserver hkp://keys.gnupg.net \
      --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -sSL https://get.rvm.io | bash -s $1
    sudo apt-get install -y \
      build-essential \
      libmysqlclient-dev \
      libsqlite3-dev
    gem install bundler
      

## Installing

The app uses a web-based installer. Once you start the server with

    > ruby app.rb
    
you should point your browser to localhost:4567 and the installation process should began.

If you want to use a Mysql database, you should create it before installing the sofware. As mysql root user, you could use something like

    CREATE DATABASES buhos;
    CREATE USER buhos_user@localhost IDENTIFIED BY 'password';
    GRANT ALL PRIVILEGES ON buhos.* TO buhos_user@localhost;
    FLUSH PRIVILEGES;

First, you define the installation language. Second, you should provide information about database support (sqlite / mysql). If you have a SCOPUS API key, you could provide it along proxy settings.
Finnaly, the database will be populated and you should restart the application to start using it.

    

## Deployment

For individual users, the application could be run without problem running app.rb using a local sqlite.

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
* [RubyMine](https://www.jetbrains.com/ruby/) - A good Ruby IDE

## Contributing

If you want to contribute, just send a email to clbustos_at_gmail.com. If you want to send a patch, the preferred method is fork the repository on [github](https://github.com/clbustos/buhos) and make a pull request.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/clbustos/buhos/tags). 

## Authors

* **Claudio  Bustos** - *Main developer* - [clbustos](https://github.com/clbustos)
* **Daniel Lermanda** - *Web page designer*



## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE.md](LICENSE.md) file for details


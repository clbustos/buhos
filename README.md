<img src="http://buhos.org/public/logo.svg" width="225" alt="Buhos Logo" />

[![CircleCI](https://circleci.com/gh/clbustos/buhos/tree/master.svg?style=svg)](https://circleci.com/gh/clbustos/buhos/tree/master)
[![Maintainability](https://api.codeclimate.com/v1/badges/ffa582598127f86ed405/maintainability)](https://codeclimate.com/github/clbustos/buhos/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/ffa582598127f86ed405/test_coverage)](https://codeclimate.com/github/clbustos/buhos/test_coverage)

Web based platform to manage complete process of systematic literature reviews. Developed using Sinatra, a Ruby-based DSL.


## Features

* Multi-platform:  Runs on Linux (tested on Ubuntu 14.04, 16.06, 18.4 and 21.04), Windows (tested on Windows 7 and 10) and MacOS (tested on High Sierra)
* Supports individual and group-based systematic reviews.
* Internal messaging system for personal messages o messages related to systematic reviews.
* Internationalization, using *I18n*. Available in English and Spanish.
* Flexible work-flow.  The main stages of text searching, screening relevant articles, data extraction and reporting are clearly defined.  However, changes can be made at any stage already finalized, and will automatically reflect in subsequent stages.
* Imports information from various bibliographic databases, such 
  as - WoS, Scopus, Ebscohost, Scielo, Pubmed, Lilacs and Proquest -  
  using BibTeX and RIS formats.
* Integration with Crossref allows deduplication of articles (using DOI), and searching for information on references
* File repository.  PDF and ODF file viewing support online via [ViewerJS](http://viewerjs.org/).
* Multiple ways to analyze data: comments and tagging at each stage of review, and generation of customized forms for information extraction.
* Various report types:  For data extracted from texts, detailed reports on the decision process at each review stage, as well as a [PRISMA flow diagram](http://prisma-statement.org/prismastatement/flowdiagram.aspx) for process overviews, ready for publication. 
* Different export file types: Can export references as BibTeX and generate GraphML, to graph relations between papers.
* Unit and integration tests for main software features. See https://buhos.org/api/file.rspec.html .

Using Kitchenham & Chartes (2007), Buhos support the 'conducting the review' phase in full, and have partial support for other stages:

### Planning the review

Stage                                     | Support
------------------------------------------|--------
Identification of the need for a review   | No
Commissioning a review                    | No
Specifying the research question(s)       | Yes
Developing a review protocol              | Yes
Evaluating the review protocol            | No

### Conducting the review

Stage                                     | Support
------------------------------------------|--------
Identification of research                | Yes
Selection of primary studies              | Yes
Study quality assessment                  | Yes
Data extraction and monitoring            | Yes
Data synthesis                            | Yes

### Reporting the review

Stage                                     | Support
------------------------------------------|--------
Specifying dissemination mechanisms       | No
Formatting the main report                | Partial
Evaluating the report                     | No



## Documentation

There is a user manual available in [English](https://buhos.org/manual/en/) and  [Spanish](https://buhos.org/manual/es/) with a quick guide for understanding the systematic review methodology that supports the software.

The API is documented using [Yard](https://yardoc.org/) and is available on [https://www.buhos.org/api](https://www.buhos.org/api). Only available in English.



## Get Started

There is a demo available on [https://demo.buhos.org](https://demo.buhos.org). You could use the software using 'admin' as username and password. Don't do anything important here, because the database is refreshed periodically.

### On Windows

The installer for Windows, can be obtained from [Buhos Windows Toolkit](https://github.com/clbustos/buhos-windows-tk/tree/master/windows_installer)

### On *nix

For Debian, Ubuntu and CentOS, packages and installation instructions are available on [packager.io](https://packager.io/gh/clbustos/buhos).    For example, to install Buhos on Ubuntu follow the instructions below, using localhost:4567 as URL.

    wget -qO- https://dl.packager.io/srv/clbustos/buhos/key | sudo apt-key add -
    sudo wget -O /etc/apt/sources.list.d/buhos.list \ 
      https://dl.packager.io/srv/clbustos/buhos/master/installer/ubuntu/16.04.repo
    sudo apt-get update
    sudo apt-get install buhos
    sudo buhos config:set PORT=4567
    sudo buhos scale web=1
    sudo buhos restart

### Using vagrant

On vendor/vagrant_alpine and vendor/vagrant_ubuntu_16 directories, working vagrant configurations for Alpine and Ubuntu 16.04 can be found, respectively.  They can be run using
    
    > vagrant up
    
By default, the application is configured to run on port 4567.
    
### Using source code (latest)

#### Prerequisites


On Linux, a ruby 2.4 or 2.5 installation with bundler is needed, and development libraries for MySQL and SQLite. We recommend using [RVM](https://rvm.io/).


On Ubuntu, the following script installs all required dependencies:


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

Once all the dependencies are installed, the source code can be copied using

   > git clone git@github.com:clbustos/buhos.git

Install required Ruby dependencies using bundler

   > bundle install
   
And run the application using

   > ruby app.rb

or

   > rackup   

## Post-install configuration

The app uses a web-based configuration.  Once the server starts, point your browser by default to localhost:4567 to begin the installation process.

If you wish to use a MySQL database, you should create it before configuring the sofware.  Using the MySQL root user, the instructions would be:

    CREATE DATABASE buhos;
    CREATE USER buhos_user@localhost IDENTIFIED BY 'password';
    GRANT ALL PRIVILEGES ON buhos.* TO buhos_user@localhost;
    FLUSH PRIVILEGES;

First, the installation language should be defined.  Second, information on the specific database should be provided (SQLite / MySQL). By default, a SQLite database will be installed in db.sqlite. If you have a SCOPUS API key, the relevant information can be submitted along with the proxy settings, if applicable.
As the final step, the database will be populated. You must restart the application before using it.

## Deployment

Individual users can run the application smoothly with the Windows installer or the packages for Ubuntu, Debian or CentOS.

For multiple online users, the use of Buho has been tested deployed on an independent HTTP server, using Passenger as connector with Nginx. MySQL has been used for the database.  In theory, the software should  work smoothly on MariaDB and Apache.

A typical nginx configuration should look like this:
    
    server {
      listen 80
      root /home/<user>/<base_dir>;
      passenger_enabled on;
      passenger_ruby <ruby_location>
    }

The location of the Ruby executable can be obtained with

    > which ruby

If you are using [RVM](https://rvm.io/) with Passenger, check [this page](https://rvm.io/deployment/passenger)

## Caveats

Since October 2018, ImageMagick have strict policies to convert pdf to images. If you need to parse pdf as images in Buhos (rarely needed), or test the software using the specification suite, check [this Stack Overflow entry](https://stackoverflow.com/questions/42928765/convertnot-authorized-aaaa-error-constitute-c-readimage-453).     



## Built With
* [Sinatra](http://sinatrarb.com/) - Sinatra is a DSL for quickly creating web applications on Ruby with minimal effort.
* [Sequel](https://github.com/jeremyevans/sequel) - Sequel is a simple, flexible, and powerful SQL database access toolkit for Ruby. It offers an abstraction layer and ORM functionalities, among other things.
* [Bootstrap](https://getbootstrap.com/) -  Bootstrap is an open source toolkit for developing with HTML, CSS, and JS.
* [jQuery](https://jquery.com/) - jQuery is a fast, small, and feature-rich JavaScript library.
* [ViewerJS](http://viewerjs.org/) - ViewerJS enables online viewing of PDF and ODT files. 
* [RubyMine](https://www.jetbrains.com/ruby/) - An excellent Ruby IDE

## Contributing

If you wish to contribute,  email clbustos_at_gmail.com. If you'd like to send a patch, best is to create a fork of the repository on [github](https://github.com/clbustos/buhos) and make a pull request.

## Versioning

We use [SemVer](http://semver.org/) for versioning.  To see the available versions, see the [tags on this repository](https://github.com/clbustos/buhos/tags).

## Authorship

### Developers

* **Claudio  Bustos** - *Main developer* - [clbustos](https://github.com/clbustos)

### Contributions
* **Daniel Lermanda** - Web page designer and UX advisor
* **María Gabriela Morales** - First conceptualization and revision of the manual
* **Liz Medina** -  English translation of  home page and manual.
* **Alejandro Díaz, Pedro Salcedo**: Development of user requirement specifications.
* **Anna Hawrot**: Polki (polish) translation and software tester.

### Citation

If you use this software for your research, please cite the following paper:

Bustos, C., Morales, M.G., Salcedo, P., & Díaz, Alejandro (2018). Buhos: A web-based systematic literature review management software. SoftwareX, 7, 360-372. [https://doi.org/10.1016/j.softx.2018.10.004](https://doi.org/10.1016/j.softx.2018.10.004)  




## License


This project is licensed under the BSD 3-Clause License - See [LICENSE](LICENSE) file for details.

FROM ubuntu:18.04
MAINTAINER Duc An <me@clgt.io>

# ENV
ENV DEBIAN_FRONTEND noninteractive
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
ENV TZ         Asia/Saigon

SHELL ["/bin/bash", "-c"]

# timezone and locale
RUN apt-get update \
    && apt-get install -y software-properties-common \
        language-pack-en-base sudo \
        apt-utils tzdata locales \
        curl wget gcc g++ make autoconf libc-dev pkg-config \
    && locale-gen en_US.UTF-8 \
    && echo $TZ > /etc/timezone \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && apt-get autoclean \
    && rm -vf /var/lib/apt/lists/*.* /tmp/* /var/tmp/*

# nginx php
RUN add-apt-repository -y ppa:nginx/stable \
    && add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y \
    zlib1g-dev \
    vim \
    sudo \
    dialog \
    net-tools \
    git \
    nginx \
    php7.4-common \
    php7.4-dev \
    php7.4-fpm \
    php7.4-bcmath \
    php7.4-curl \
    php7.4-gd \
    php7.4-imagick \
    php7.4-intl \
    php7.4-json \
    php7.4-ldap \
    php7.4-mbstring \
    php7.4-mysqlnd \
    php7.4-pgsql \
    php7.4-redis \
    php7.4-xml \
    php7.4-soap \
    php7.4-amqp \
&& phpdismod xdebug opcache \
&& mkdir /run/php && chown www-data:www-data /run/php \
&& apt-get autoclean \
&& rm -vf /var/lib/apt/lists/*.* /var/tmp/*

# Install php-snappy
RUN git clone -b 0.1.9 --recursive --depth=1 https://github.com/kjdev/php-ext-snappy.git \
    && cd php-ext-snappy \
    && phpize \
    && ./configure && make && make install \
    && echo "extension=snappy.so" > /etc/php/7.4/mods-available/snappy.ini \
    && phpenmod snappy \
    && cd .. && rm -rf php-ext-snappy

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
&& apt-get autoclean \
&& rm -vf /var/lib/apt/lists/*.*

# configuration
COPY conf/nginx/vhost.conf /etc/nginx/sites-available/default
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/php74/php.ini /etc/php/7.4/fpm/php.ini
COPY conf/php74/cli.php.ini /etc/php/7.4/cli/php.ini
COPY conf/php74/php-fpm.conf /etc/php/7.4/fpm/php-fpm.conf
COPY conf/php74/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Start Supervisord
COPY ./start.sh /start.sh
RUN chmod 755 /start.sh

EXPOSE 80 443

CMD ["/bin/bash", "/start.sh"]
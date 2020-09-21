FROM php:7.4-fpm

RUN addgroup --gid 3000 --system app && adduser --uid 3000 --system --disabled-login --disabled-password --gid 3000 app

RUN apt-get update && apt-get install -qqy git unzip libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libaio1 wget && apt-get clean autoclean && apt-get autoremove --yes &&  rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN docker-php-ext-install pdo pdo_mysql \
        && apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
        && docker-php-ext-configure gd --with-freetype --with-jpeg \
        && pecl install redis-5.1.1 \
        && apt-get install -y libcurl4-gnutls-dev \
                zlib1g-dev libicu-dev g++ libxml2-dev libpq-dev \
        && docker-php-ext-install curl json xml pdo_pgsql pgsql \
        && apt-get install -y libmemcached-dev zlib1g-dev \
        && pecl install memcached \
        && docker-php-ext-enable memcached redis


#composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# ORACLE oci
RUN mkdir /opt/oracle \
    && cd /opt/oracle

ADD instantclient-basic-linux.x64-12.1.0.2.0.zip /opt/oracle
ADD instantclient-sdk-linux.x64-12.1.0.2.0.zip /opt/oracle

# Install Oracle Instantclient
RUN  unzip /opt/oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && unzip /opt/oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so \
    && ln -s /opt/oracle/instantclient_12_1/libclntshcore.so.12.1 /opt/oracle/instantclient_12_1/libclntshcore.so \
    && ln -s /opt/oracle/instantclient_12_1/libocci.so.12.1 /opt/oracle/instantclient_12_1/libocci.so \
    && rm -rf /opt/oracle/*.zip

ENV LD_LIBRARY_PATH  /opt/oracle/instantclient_12_1:${LD_LIBRARY_PATH}

# Install Oracle extensions
RUN echo 'instantclient,/opt/oracle/instantclient_12_1/' | pecl install oci8 \
      && docker-php-ext-enable \
               oci8 \
       && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_1,12.1 \
       && docker-php-ext-install \
               pdo_oci
RUN mkdir -p /var/www/html

ADD etc/php-fpm.d/www.conf /usr/loca/etc/php-fpm.d/www.conf
WORKDIR /var/www/html
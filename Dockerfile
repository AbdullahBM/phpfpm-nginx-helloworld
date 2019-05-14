FROM php:7.2-fpm
RUN mkdir /app
COPY hello.php /app

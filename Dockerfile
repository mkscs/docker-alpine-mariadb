FROM alpine:3.2
MAINTAINER mkscsy@gmail.com


RUN apk --update add mysql mysql-client && \
    rm -rf /var/cache/apk/* 
    
ADD scripts /scripts

RUN chmod +x /scripts/*.sh

EXPOSE 3306

VOLUME ["/var/lib/mysql"]

CMD ["/scripts/initialize.sh"]

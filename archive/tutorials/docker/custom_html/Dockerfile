FROM centos:7
RUN yum install -y httpd
COPY index.html /var/www/html/index.html
ENTRYPOINT [ ""/usr/sbin/httpd","-D","FOREGROUND" ]
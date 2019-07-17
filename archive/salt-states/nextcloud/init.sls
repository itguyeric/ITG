/etc/httpd/conf.modules.d/00-dav.conf
  file.managed:
    - source: salt://nextcloud/files/00-dav.conf
    - user: root
    - group: root
    - mode: 644

# install php-process to occ

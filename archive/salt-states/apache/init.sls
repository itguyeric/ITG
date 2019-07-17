httpd-install:
  pkg.installed:
    - pkgs:
      - httpd

httpd-service:
  service.running:
  - enable: True
  - reload: True
  - require:
    - pkg: httpd-install

/etc/httpd/conf.d/welcome.conf:
    file.managed:
      - source: salt://apache/files/welcome.conf
      - user: root
      - group: root
      - mode: 644

/etc/httpd/conf/httpd.conf:
  file.managed:
    - source: salt://apache/files/httpd.conf
    - user: root
    - group: root
    - mode: 644

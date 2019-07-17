mysql-install:
  pkg.installed:
    - name: mysql-server

mysql-service:
  service:
    - name: mysqld
    - running
    - enable: True
    - require:
      - pkg: mysql_package

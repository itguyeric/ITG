mariadb-repo:
  pkgrepo.managed:
    - humanname: MariaDB
    - baseurl: http://yum.mariadb.org/10.2/centos7-amd64
    - gpgkey: https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
    - gpgcheck: 1

mariadb-install:
  pkg.installed:
    - pkgs:
      - mariadb
      - mariadb-server
      - mariadb-libs
    - include:
      - sls: repo 

mariadb:
  service.running:
    - enable: True
    - reload: True
    - require:
      - pkg: mariadb-install

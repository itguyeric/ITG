lynis:
  pkgrepo.managed:
    - humanname: Lynis
    - baseurl: https://packages.cisofy.com/community/lynis/rpm/
    - gpgcheck: 1
    - gpgkey: https://packages.cisofy.com/keys/cisofy-software-rpms-public.key
    - enabled: True
    - require_in:
      - pkg: lynis_install

lynis_install:
  pkg.installed:
    - pkgs:
      - lynis
      - ca-certificates
      - curl
      - nss
      - openssl
      {% if grains.os == 'CentOS' %}
      #ansi2html converts output to html
      - https://kojipkgs.fedoraproject.org/packages/python-ansi2html/1.2.0/8.fc29/noarch/python2-ansi2html-1.2.0-8.fc29.noarch.rpm
    #  {% elif grains.os == 'Fedora' %}
    #  - python-ansi2html
      {% endif %}
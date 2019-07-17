install_rvm_key:
  cmd.run:
    - name: "gpg2 --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3"
    - shell: /bin/bash
    - unless: "stat /root/.gnupg/trustdb.gpg || gpg2 --list-keys D39DC0E3"

ruby-1.9.3:
  rvm.installed:
    - default: True
  require:
    - cmd: install_rvm_key

set_ruby:
  cmd.wait:
    - name: 'source /etc/profile.d/rvm.sh; rvm use 1.9.3 -- default'
    - shell: /bin/bash
    - stateful: False
    - require:
      - rvm: ruby-1.9.3

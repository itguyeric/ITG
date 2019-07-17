# Install and configure a GitLab server

gitlab:
  pkgrepo.managed:
    - humanname: gitlab-ce
    - baseurl: https://packages.gitlab.com/gitlab/gitlab-ce/el/7/$basearch
    - gpgcheck: 1
    - gpgkey: https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey
    - gpgkey: https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
    - require_in:
      - pkg: gitlab_install

gitlab_install:
  pkg.installed:
    - pkgs:
      - curl
      - gitlab-ce
      - pygpgme
      - yum-utils
    - include:
      - postfix

/etc/gitlab/gitlab.rb:
  file.managed:
    - source: salt://gitlab/files/gitlab.rb
    - user: root
    - group: root
    - mode: 600

#gitlab:
  #    service.running:
    #  - enable: True
    #- reload: True
  #- require:
    #    - pkg: gitlab_install

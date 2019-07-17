ehendricks:
  user.present:
    - gid: wheel
    - uid: 2001
    - unique: False
    - shell: /bin/bash
    - enforce_password: True
    - password: {{ salt['pillar.get']('ehendricks:password', "")  }}
    - fullname: 'Eric Hendricks'
    - allow_uid_change: True
    - allow_gid_change: True

ehendricks-sshkey:
  ssh_auth.present:
    - user: ehendricks
    - name: {{ salt['pillar.get']('ehendricks:ssh-key', "") }}
    - require:
      - user: ehendricks

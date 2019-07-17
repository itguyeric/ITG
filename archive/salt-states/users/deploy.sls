deploy:
  user.present:
    - uid: 1001
    - unique: False
    - shell: /bin/bash
    - enforce_password: True
    - password: {{ salt['pillar.get']('deploy:password', "")  }}
    - fullname: 'Deploy Account'
    - allow_uid_change: True
    - allow_gid_change: True

deploy-sshkey:
  ssh_auth.present:
    - user: deploy
    - name: {{ salt['pillar.get']('deploy:ssh-key', "") }}
    - require:
      - user: deploy

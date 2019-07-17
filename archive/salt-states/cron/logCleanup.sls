find /var/log/ -mtime +30 -exec rm -rf {} \;:
  cron.present:
    - user: root
    - minute: 00
    - hour: 12
    - daymonth: '*'
    - month: '*'
    - dayweek: '*'

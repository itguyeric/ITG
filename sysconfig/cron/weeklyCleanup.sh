#!/bin/bash
# Purge cache, remove orphans

/usr/bin/dnf clean all
/usr/bin/dnf autoremove -y

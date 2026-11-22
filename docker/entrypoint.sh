#!/bin/sh
# Give "user" the ids of whoever owns the mounted checkout, so files the
# container writes on the bind mounts belong to that host user, then run the
# command as "user". A checkout that reads as root's (Docker Desktop) is left
# alone.
set -e

ready=/run/entrypoint-ready
rm -f "$ready"

uid="$(stat -c %u /home/user/adamant_example)"
gid="$(stat -c %g /home/user/adamant_example)"
old_uid="$(id -u user)"
old_gid="$(id -g user)"
if [ "$uid" -ne 0 ] && [ "$gid" -ne 0 ] &&
   { [ "$uid" != "$old_uid" ] || [ "$gid" != "$old_gid" ]; }; then
  other="$(getent passwd "$uid" | cut -d: -f1)"
  if [ -n "$other" ] && [ "$other" != user ]; then userdel "$other"; fi
  other="$(getent group "$gid" | cut -d: -f1)"
  if [ -n "$other" ] && [ "$other" != user ]; then groupdel -f "$other"; fi
  sed -i "s/^user:x:$old_uid:$old_gid:/user:x:$uid:$gid:/" /etc/passwd
  sed -i "s/^user:x:$old_gid:/user:x:$gid:/" /etc/group
  find /home/user -xdev \( -user "$old_uid" -o -group "$old_gid" \) -exec chown -h "$uid:$gid" {} +
fi

touch "$ready"
exec setpriv --reuid=user --regid=user --init-groups "$@"

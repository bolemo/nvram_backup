#!/bin/sh

backup () {
  TIMESTAMP="$(date -u +%s)"
  #/bin/nvram set config_timestamp="$TIMESTAMP"
  #/bin/nvram commit
  /bin/nvram backup /nvram_backup
  if [ -d /mnt/optware ]; then
    DATE_DIR=$(awk 'BEGIN { print strftime("%Y-%m-%d_%H-%M-%S", '$TIMESTAMP'); }')
    [ -d /mnt/optware/nvram_backups ] || mkdir "/mnt/optware/nvram_backups"
    BACKUP_DIR="/mnt/optware/nvram_backups/$DATE_DIR"
    mkdir "$BACKUP_DIR"
    cp /nvram_backup "$BACKUP_DIR/nvram_backup.cfg"
    nvram show | sort > "$BACKUP_DIR/nvram_backup.txt"
  fi
}

install_bootfix () {
  { echo '#!/bin/sh /etc/rc.common';
    echo 'START=14';
    echo 'start() {';
    echo '  [ -r /nvram_backup ] && /bin/nvram restore /nvram_backup';
    echo '}';
    echo 'stop() {';
    echo '  :';
    echo '}';
    echo 'restart() {';
    echo '  stop';
    echo '  start';
    echo '}'; } >"/etc/init.d/nvramrestore"
  chmod +x /etc/init.d/nvramrestore
  cd /etc/rc.d
  ln -s ../init.d/nvramrestore /etc/rc.d/S14nvramrestore
  cd - >/dev/null
}

uninstall_bootfix () {
  [ -e /etc/init.d/nvramrestore ] && rm /etc/init.d/nvramrestore
  [ -e /etc/rc.d/S14nvramrestore ] && rm /etc/rc.d/S14nvramrestore
}

case $1 in
  "backup") backup ;;
  "bootfix")
    case $2 in
      "install") install_bootfix ;;
      "uninstall") uninstall_bootfix ;;
      *) echo "A second parameter is needed (install, uninstall)"; exit 1 ;;
    esac ;;
  "uninstall_autorestore") uninstall_autorestore ;;
  *) echo "A parameter is needed (backup, bootfix install, bootfix uninstall)"; exit 1 ;;
esac

exit 0

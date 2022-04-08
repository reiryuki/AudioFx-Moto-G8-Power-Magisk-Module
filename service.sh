(

MODPATH=${0%/*}
API=`getprop ro.build.version.sdk`

# debug
exec 2>$MODPATH/debug.log
set -x

# prevent soft reboot
echo 0 > /proc/sys/kernel/panic
echo 0 > /proc/sys/kernel/panic_on_oops
echo 0 > /proc/sys/kernel/panic_on_rcu_stall
echo 0 > /proc/sys/kernel/panic_on_warn
echo 0 > /proc/sys/vm/panic_on_oom

# file
NAME="ap_gain.bin ap_gain_mmul.bin"
for NAMES in $NAME; do
  if [ ! -f /data/vendor/$NAMES ]; then
    cp -f /vendor/etc/$NAMES /data/vendor
    chmod 0600 /data/vendor/$NAMES
    chown 1013.1013 /data/vendor/$NAMES
  fi
done

# wait
sleep 20

# mount
AML=/data/adb/modules/aml
if [ ! -d $AML ] || [ -f $AML/disable ]; then
  DIR=$MODPATH/system/vendor
else
  DIR=$AML/system/vendor
fi
FILE=`find $DIR/odm/etc -maxdepth 1 -type f -name *audio*effects*.conf\
      -o -name *audio*effects*.xml -o -name *audio*policy*.conf\
      -o -name *stage*policy*.conf -o -name *audio*policy*.xml`
if [ "$FILE" ]; then
  for i in $FILE; do
    j="$(echo $i | sed "s|$DIR||")"
    umount $j
    mount -o bind $i $j
  done
fi

# restart
killall audioserver

# wait
sleep 40

# allow
PKG=com.motorola.audiofx
if [ "$API" -gt 29 ]; then
  appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
fi
PID=`pidof $PKG`
if [ $PID ]; then
  echo -17 > /proc/$PID/oom_adj
  echo -1000 > /proc/$PID/oom_score_adj
fi

) 2>/dev/null



(

MODPATH=${0%/*}
API=`getprop ro.build.version.sdk`
AML=/data/adb/modules/aml

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

# restart
killall audioserver

# wait
sleep 20

# mount
NAME="*audio*effects*.conf -o -name *audio*effects*.xml -o -name *policy*.conf -o -name *policy*.xml"
if [ ! -d $AML ] || [ -f $AML/disable ]; then
  DIR=$MODPATH/system/vendor
else
  DIR=$AML/system/vendor
fi
FILE=`find $DIR/odm/etc -maxdepth 1 -type f -name $NAME`
if [ "`realpath /odm/etc`" != /vendor/odm/etc ] && [ "$FILE" ]; then
  for i in $FILE; do
    j="$(echo $i | sed "s|$DIR||")"
    umount $j
    mount -o bind $i $j
  done
  killall audioserver
fi
if [ ! -d $AML ] || [ -f $AML/disable ]; then
  DIR=$MODPATH/system
else
  DIR=$AML/system
fi
FILE=`find $DIR/etc -maxdepth 1 -type f -name $NAME`
if [ -d /my_product/etc ] && [ "$FILE" ]; then
  for i in $FILE; do
    j="$(echo $i | sed "s|$DIR||")"
    umount /my_product$j
    mount -o bind $i /my_product$j
  done
  killall audioserver
fi

# wait
sleep 40

# allow
PKG=com.motorola.audiofx
if [ "$API" -ge 30 ]; then
  appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
fi
PID=`pidof $PKG`
if [ $PID ]; then
  echo -17 > /proc/$PID/oom_adj
  echo -1000 > /proc/$PID/oom_score_adj
fi

) 2>/dev/null



ui_print " "

# magisk
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`find /dev -mindepth 2 -maxdepth 2 -type d -name .magisk`
fi

# info
MODVER=`grep_prop version $MODPATH/module.prop`
MODVERCODE=`grep_prop versionCode $MODPATH/module.prop`
ui_print "id=$MODID"
ui_print "version=$MODVER"
ui_print "versionCode=$MODVERCODE"
ui_print "MagiskVersion=$MAGISK_VER"
ui_print "MagiskVersionCode=$MAGISK_VER_CODE"
ui_print " "

# sdk
NUM=26
if [ "$API" -lt $NUM ]; then
  ui_print "! Unsupported SDK $API. You have to upgrade your"
  ui_print "  Android version at least SDK API $NUM to use this"
  ui_print "  module."
  abort
else
  ui_print "- SDK $API"
  ui_print " "
fi

# sepolicy.rule
if [ "$BOOTMODE" != true ]; then
  mount -o rw -t auto /dev/block/bootdevice/by-name/persist /persist
  mount -o rw -t auto /dev/block/bootdevice/by-name/metadata /metadata
fi
FILE=$MODPATH/sepolicy.sh
DES=$MODPATH/sepolicy.rule
if [ -f $FILE ] && ! getprop | grep -Eq "sepolicy.sh\]: \[1"; then
  mv -f $FILE $DES
  sed -i 's/magiskpolicy --live "//g' $DES
  sed -i 's/"//g' $DES
fi

# .aml.sh
mv -f $MODPATH/aml.sh $MODPATH/.aml.sh

# mod ui
if getprop | grep -Eq "mod.ui\]: \[1"; then
  APP=AudioFxMoto
  FILE=/sdcard/$APP.apk
  DIR=`find $MODPATH/system -type d -name $APP`
  ui_print "- Using modified UI apk..."
  if [ -f $FILE ]; then
    cp -f $FILE $DIR
    chmod 0644 $DIR/$APP.apk
    ui_print "  Applied"
  else
    ui_print "  ! There is no $FILE file."
    ui_print "    Please place the apk to your internal storage first"
    ui_print "    and reflash!"
  fi
  ui_print " "
fi

# cleaning
ui_print "- Cleaning..."
APP="`ls $MODPATH/system/priv-app` `ls $MODPATH/system/app`"
PKG="com.motorola.audiofx
     com.motorola.motosignature.app"
if [ "$BOOTMODE" == true ]; then
  for PKGS in $PKG; do
    RES=`pm uninstall $PKGS`
  done
fi
for APPS in $APP; do
  rm -f `find /data/dalvik-cache /data/resource-cache -type f -name *$APPS*.apk`
done
rm -rf /metadata/magisk/$MODID
rm -rf /mnt/vendor/persist/magisk/$MODID
rm -rf /persist/magisk/$MODID
rm -rf /data/unencrypted/magisk/$MODID
rm -rf /cache/magisk/$MODID
ui_print " "

# function
cleanup() {
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
DIR=/data/adb/modules_update/$MODID
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
}

# cleanup
DIR=/data/adb/modules/$MODID
FILE=$DIR/module.prop
if getprop | grep -Eq "audiofx.cleanup\]: \[1"; then
  ui_print "- Cleaning-up $MODID data..."
  cleanup
  ui_print " "
elif [ -d $DIR ] && ! grep -Eq "$MODNAME" $FILE; then
  ui_print "- Different version detected"
  ui_print "  Cleaning-up $MODID data..."
  cleanup
  ui_print " "
fi

# function
hide_oat() {
for APPS in $APP; do
  mkdir -p `find $MODPATH/system -type d -name $APPS`/oat
  touch `find $MODPATH/system -type d -name $APPS`/oat/.replace
done
}
replace_dir() {
if [ -d $DIR ]; then
  mkdir -p $MODDIR
  touch $MODDIR/.replace
fi
}
hide_app() {
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/system/app/$APPS
else
  DIR=/system/app/$APPS
fi
MODDIR=$MODPATH/system/app/$APPS
replace_dir
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/system/priv-app/$APPS
else
  DIR=/system/priv-app/$APPS
fi
MODDIR=$MODPATH/system/priv-app/$APPS
replace_dir
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/product/app/$APPS
else
  DIR=/product/app/$APPS
fi
MODDIR=$MODPATH/system/product/app/$APPS
replace_dir
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/product/priv-app/$APPS
else
  DIR=/product/priv-app/$APPS
fi
MODDIR=$MODPATH/system/product/priv-app/$APPS
replace_dir
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/product/preinstall/$APPS
else
  DIR=/product/preinstall/$APPS
fi
MODDIR=$MODPATH/system/product/preinstall/$APPS
replace_dir
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/system_ext/app/$APPS
else
  DIR=/system/system_ext/app/$APPS
fi
MODDIR=$MODPATH/system/system_ext/app/$APPS
replace_dir
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/system_ext/priv-app/$APPS
else
  DIR=/system/system_ext/priv-app/$APPS
fi
MODDIR=$MODPATH/system/system_ext/priv-app/$APPS
replace_dir
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/vendor/app/$APPS
else
  DIR=/vendor/app/$APPS
fi
MODDIR=$MODPATH/system/vendor/app/$APPS
replace_dir
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/vendor/euclid/product/app/$APPS
else
  DIR=/vendor/euclid/product/app/$APPS
fi
MODDIR=$MODPATH/system/vendor/euclid/product/app/$APPS
replace_dir
}
check_app() {
if [ "$BOOTMODE" == true ]; then
  for APPS in $APP; do
    FILE=`find $MAGISKTMP/mirror/system_root/system\
               $MAGISKTMP/mirror/system_root/product\
               $MAGISKTMP/mirror/system_root/system_ext\
               $MAGISKTMP/mirror/system\
               $MAGISKTMP/mirror/product\
               $MAGISKTMP/mirror/system_ext\
               $MAGISKTMP/mirror/vendor -type f -name $APPS.apk`
    if [ "$FILE" ]; then
      ui_print "  Checking $APPS.apk"
      ui_print "  Please wait..."
      if grep -Eq $UUID $FILE; then
        ui_print "  Your $APPS.apk will be hidden"
        hide_app
      fi
    fi
  done
fi
}
detect_soundfx() {
if [ "$BOOTMODE" == true ]\
&& dumpsys media.audio_flinger | grep -Eq $UUID; then
  ui_print "- $NAME is detected."
  ui_print "  It may be conflicting with this module."
  ui_print "  You can run terminal:"
  ui_print " "
  ui_print "  su"
  ui_print "  setprop disable.dirac 1"
  ui_print " "
  ui_print "  and reinstall this module if you want to disable it."
  ui_print " "
fi
}

# hide
hide_oat
APP=MusicFX
for APPS in $APP; do
  hide_app
done
if getprop | grep -Eq "disable.dirac\]: \[1" || getprop | grep -Eq "disable.misoundfx\]: \[1"; then
  APP=MiSound
  for APPS in $APP; do
    hide_app
  done
fi
if getprop | grep -Eq "disable.dirac\]: \[1"; then
  APP="Dirac DiracAudioControlService"
  for APPS in $APP; do
    hide_app
  done
fi

# dirac & misoundfx
FILE=$MODPATH/.aml.sh
APP="XiaomiParts
     ZenfoneParts
     ZenParts
     GalaxyParts
     KharaMeParts
     DeviceParts"
NAME='dirac soundfx'
UUID=e069d9e0-8329-11df-9168-0002a5d5c51b
if getprop | grep -Eq "disable.dirac\]: \[1"; then
  ui_print "- $NAME will be disabled"
  sed -i 's/#2//g' $FILE
  check_app
  ui_print " "
else
  detect_soundfx
fi
FILE=$MODPATH/.aml.sh
NAME=misoundfx
UUID=5b8e36a5-144a-4c38-b1d7-0002a5d5c51b
if getprop | grep -Eq "disable.misoundfx\]: \[1"; then
  ui_print "- $NAME will be disabled"
  sed -i 's/#3//g' $FILE
  check_app
  ui_print " "
else
  if [ "$BOOTMODE" == true ]\
  && dumpsys media.audio_flinger | grep -Eq $UUID; then
    ui_print "- $NAME is detected."
    ui_print "  It may be conflicting with this module."
    ui_print "  You can run terminal:"
    ui_print " "
    ui_print "  su"
    ui_print "  setprop disable.misoundfx 1"
    ui_print " "
    ui_print "  and reinstall this module if you want to disable it."
    ui_print " "
  fi
fi

# dirac_controller
FILE=$MODPATH/.aml.sh
NAME='dirac_controller soundfx'
UUID=b437f4de-da28-449b-9673-667f8b964304
if getprop | grep -Eq "disable.dirac\]: \[1"; then
  ui_print "- $NAME will be disabled"
  ui_print " "
else
  detect_soundfx
fi

# dirac_music
FILE=$MODPATH/.aml.sh
NAME='dirac_music soundfx'
UUID=b437f4de-da28-449b-9673-667f8b9643fe
if getprop | grep -Eq "disable.dirac\]: \[1"; then
  ui_print "- $NAME will be disabled"
  ui_print " "
else
  detect_soundfx
fi

# dirac_gef
FILE=$MODPATH/.aml.sh
NAME='dirac_gef soundfx'
UUID=3799D6D1-22C5-43C3-B3EC-D664CF8D2F0D
if getprop | grep -Eq "disable.dirac\]: \[1"; then
  ui_print "- $NAME will be disabled"
  ui_print " "
else
  detect_soundfx
fi

# stream mode
FILE=$MODPATH/.aml.sh
PROP=`getprop stream.mode`
if echo "$PROP" | grep -Eq m; then
  ui_print "- Activating music stream..."
  sed -i 's/#m//g' $FILE
  sed -i 's/musicstream=/musicstream=true/g' $MODPATH/acdb.conf
  ui_print " "
else
  APP=AudioFX
  for APPS in $APP; do
    hide_app
  done
fi
if echo "$PROP" | grep -Eq r; then
  ui_print "- Activating ring stream..."
  sed -i 's/#r//g' $FILE
  ui_print " "
fi
if echo "$PROP" | grep -Eq a; then
  ui_print "- Activating alarm stream..."
  sed -i 's/#a//g' $FILE
  ui_print " "
fi
if echo "$PROP" | grep -Eq v; then
  ui_print "- Activating voice_call stream..."
  sed -i 's/#v//g' $FILE
  ui_print " "
fi
if echo "$PROP" | grep -Eq n; then
  ui_print "- Activating notification stream..."
  sed -i 's/#n//g' $FILE
  ui_print " "
fi

# audio rotation
FILE=$MODPATH/service.sh
if getprop | grep -Eq "audio.rotation\]: \[1"; then
  ui_print "- Activating ro.audio.monitorRotation=true"
  sed -i '1i\
resetprop ro.audio.monitorRotation true' $FILE
  ui_print " "
fi

# raw
FILE=$MODPATH/.aml.sh
if getprop | grep -Eq "disable.raw\]: \[0"; then
  ui_print "- Not disabling Ultra Low Latency playback (RAW)"
  ui_print " "
else
  sed -i 's/#u//g' $FILE
fi

# other
FILE=$MODPATH/service.sh
if getprop | grep -Eq "other.etc\]: \[1"; then
  ui_print "- Activating other etc files bind mount..."
  sed -i 's/#p//g' $FILE
  ui_print " "
fi

# permission
ui_print "- Setting permission..."
DIR=`find $MODPATH/system/vendor -type d`
for DIRS in $DIR; do
  chown 0.2000 $DIRS
done
magiskpolicy --live "type system_lib_file"
magiskpolicy --live "type vendor_file"
magiskpolicy --live "type vendor_configs_file"
magiskpolicy --live "dontaudit { vendor_file vendor_configs_file } labeledfs filesystem associate"
magiskpolicy --live "allow     { vendor_file vendor_configs_file } labeledfs filesystem associate"
magiskpolicy --live "dontaudit init { vendor_file vendor_configs_file } dir relabelfrom"
magiskpolicy --live "allow     init { vendor_file vendor_configs_file } dir relabelfrom"
magiskpolicy --live "dontaudit init { vendor_file vendor_configs_file } file relabelfrom"
magiskpolicy --live "allow     init { vendor_file vendor_configs_file } file relabelfrom"
chcon -R u:object_r:vendor_file:s0 $MODPATH/system/vendor
chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/etc
chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/odm/etc
ui_print " "





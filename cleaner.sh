PKG="com.motorola.motosignature.app
     com.motorola.audiofx"
for PKGS in $PKG; do
  rm -rf /data/user/*/$PKGS/cache/*
done



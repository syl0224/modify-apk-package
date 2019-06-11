if [ X"$1" = X"" ] ; then
    echo "Usage: signapk [apk]"
    return 
fi
apkSrc=$1
apkDes=${apkSrc%.*}_resigned.apk
MY_PATH=$(cd "$(dirname $0)"; pwd)
echo "sign apk:$apkSrc"
echo "----> to:$apkDes"
java -jar $MY_PATH/signapk.jar $MY_PATH/testkey.x509.pem $MY_PATH/testkey.pk8 $apkSrc $apkDes

#!/usr/bin/env bash

OUTPUT='test'
MANIFEST_FILE='AndroidManifest.xml'
SCRIPT_PATH=`pwd`
APKTOOL=./apktool2
AAPT=./aapt

function get_old_package () {
    apk=$1
    old_pack_name=`$AAPT dump badging $apk|grep package |awk '{print $2}'`
    old_pack_name=${old_pack_name:5}
    old_pack_name=${old_pack_name//"'"/""}
    echo $old_pack_name
}

#apktool d $apk -o test
function decompress_package() {
    echo 'apktool d apk -o test...'
    apk=$1
    rm -rf $OUTPUT
    $APKTOOL d $apk -o $OUTPUT
}

function modify_manifest() {
    old_pack_name=$1
    pack_name=$2
    sed -i '' "s/$old_pack_name/$pack_name/g" $OUTPUT/$MANIFEST_FILE
}

function modify_smali() {
    old_pack_name=$1
    pack_name=$2
    cd $SCRIPT_PATH'/'$OUTPUT'/smali'

    old_pack_path=${old_pack_name//"."/"/"}'/'
    pack_path=${pack_name//"."/"/"}'/'
    echo 'old_pack_path='$old_pack_path', pack_path='$pack_path
    mkdir tmp
    cp -r $old_pack_path tmp

    old_pack_path_transfer=${old_pack_name//"."/"\/"}'\/'
    pack_path_transfer=${pack_name//"."/"\/"}'\/'
    echo 'old_pack_path_transfer='$old_pack_path_transfer',  pack_path_transfer='$pack_path_transfer
    sed -i '' "s/$old_pack_path_transfer/$pack_path_transfer/g" `grep $old_pack_path -rl $SCRIPT_PATH'/'$OUTPUT'/smali/tmp'`

    old_pack_root=`echo $old_pack_name |cut -d "." -f1`
    echo 'old_pack_root='$old_pack_root
    rm -rf $old_pack_root
    path=${pack_name//"."/" "}
    for dir in $path
    do
        echo 'mkdir '$dir
        mkdir $dir
        cd $dir
    done
    cd $SCRIPT_PATH'/'$OUTPUT'/smali'
    cp -r tmp/ $pack_path
    rm -rf tmp
}

function compress_package() {
    pack_name=$1
    cd $SCRIPT_PATH
    $APKTOOL b -d $OUTPUT -o $pack_name'.apk'
}

function sign_apk() {
    pack_name=$1
    java -jar ./signapk/signapk.jar ./signapk/testkey.x509.pem ./signapk/testkey.pk8 $pack_name'.apk' $pack_name'.sign.apk'
}

function run() {
    apk=$1
    pack_name=$2

    #get old package name
    old_pack_name=`get_old_package $apk`
    echo "old_pack_name="$old_pack_name

    #apktool d $apk -o test
    decompress_package $apk

    #replace AndroidManifest.xml's package name
    echo "replace AndroidManifest.xml's package name ..."
    modify_manifest $old_pack_name $pack_name

    #replace all smali files's package name
    echo "replace all smali files's package name ..."
    modify_smali $old_pack_name $pack_name

    #apktool b -d test -o $pack_name.apk
    compress_package $pack_name

    #sign apk
    echo 'sign apk...'
    sign_apk $pack_name
}

apk=$1
pack_name=$2
echo 'apk='$apk', pack_name='$pack_name
rm $pack_name'.apk' || true
rm $pack_name'.sign.apk' || true

run $apk $pack_name
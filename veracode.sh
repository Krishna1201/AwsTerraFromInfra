#!/bin/bash

set -e

mapfile -t array  < <(cat manifest.json | jq -r '.Versions |keys[] as $k | "\($k)"'| tr -d '\r'|sort)
mapfile -t array2 < <(cat manifest.json | jq -r '.Versions[] |with_entries(.values |= .Version)' | jq -r .[] | tr -d '\r'|sort)

file=`for ((i=0;i<${#array[@]};++i)); do combined=( "jfrog rt dl --flat=true ""\"default.generic.cloud/wm-opswb/services/"${array[i]}"/"${array2[i]}.zip\""");  printf "%s\n" "${combined[@]}" ; done`

for ((i=0;i<${#file[@]};++i))
do
eval "$file"
done

for ((i=0;i<${#array[@]};++i))
do
name=`printf "%s\n" "${array[i]}"`
echo ${name}
file=`printf "%s\n" "${array2[i]}"`
java -jar veracode-wrapper.jar -vid ${VERACODE_ID} -vkey ${VERACODE_KEY} \
    -action UploadAndScan -appname "Operations Workbench" -createprofile false -sandboxname "CodepipelineScan"-${name} \
    -createsandbox true -scanallnonfataltoplevelmodules true -filepath ${file}.zip -version `date "+%m-%d-%y-%I%M%S"`-${name} -exclude a204309-git2s3-outputbucket_plan
done
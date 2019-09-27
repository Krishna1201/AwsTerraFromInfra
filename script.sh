#!/bin/bash

set -ex

mapfile -t array  < <(cat manifest.json | jq -r '.Versions |keys[] as $k | "\($k)"'| tr -d '\r'|sort)
mapfile -t array2 < <(cat manifest.json | jq -r '.Versions[] |with_entries(.values |= .Version)' | jq -r .[] | tr -d '\r'|sort)

file=`for ((i=0;i<${#array[@]};++i)); do combined=( "jfrog rt dl --flat=true --explode=true ""\"default.generic.cloud/wm-opswb/services/"${array[i]}"/"${array2[i]}.zip\"" ""${array[i]}/");  printf "%s\n" "${combined[@]}" ; done`

for ((i=0;i<${#file[@]};++i))
do
eval "$file"
done

for ((i=0;i<${#array[@]};++i))
do
cd "${array[i]}"
CURRENT_VERSION=`echo "${array2[i]}" | grep -oP "[0-9].*"`
echo "Zipping Lambda DLLs and pushing to s3"
names=$(grep -oPr --include=\*.tf 'code_s3_key_zip_name.*' terraform/modules/v1 --exclude={variables.tf,main.tf} |sed 's/^.*= //'| tr -d '"' | sed 's/.\{4\}$//'; )
Bucket_Key=$(grep -ro --include=\variables.tf 'code_s3_bucket_folder =.*' terraform/ |sed 's/^.*= //'| tr -d '"'| grep -v '\$')
    counter=0
    for name in $names
    do
    chmod --recursive a+r $name*/dist
    zip -jr $name.zip $name*/dist
    aws s3 cp $name.zip s3://a204309-qa-lambda-source-code/v1/$Bucket_Key/
    done
cd terraform
terraform init
terraform workspace select QA || terraform workspace new QA
terraform plan -no-color -input=false -out=${array[i]}_plan -var "tf_version=$CURRENT_VERSION";
terraform apply ${array[i]}_plan;
cd ../..
done
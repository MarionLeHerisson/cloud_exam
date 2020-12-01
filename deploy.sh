#!/bin/bash

ssh-keygen -f my-awesome-key-pair -N ""

myip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
echo "variable \"MY_IP\" {
  default = \"${myip}\"
}" > vars.tf


terraform init
# terraform plan
terraform apply -auto-approve


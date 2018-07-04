#!/bin/bash
#
# Script to destroy a VPC in AWS EC2
#
. tag.sh
. lib.sh
if [[ -z "$VPCTAG" ]]; then
    echo "Danger : please define your tag in tag.sh"
    exit
fi


ec2 describe-vpcs --filters Name=tag:vpctag,Values="${VPCTAG}" --output text > vpcs.txt

for VPC in `cat vpcs.txt | grep VPCS | awk '{print $7}'`; do
    vftrace "Delete VPC $VPC..."
    ec2 delete-vpc --vpc-id $VPC
    vfctrace "\n"
done

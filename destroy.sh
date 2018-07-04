#!/bin/bash
#
# Script to destroy a VPC in AWS EC2
#
if [[ "$1" = "-v" ]]; then
    VERBOSE=true
fi

. tag.sh
. lib.sh
if [[ -z "$VPCTAG" ]]; then
    echo "Danger : please define your tag in tag.sh"
    exit
fi


ec2 describe-vpcs --filters Name=tag:vpctag,Values="${VPCTAG}" --output text > vpcs.txt

for VPC in `cat vpcs.txt | grep VPCS | awk '{print $7}'`; do
    vftrace "Delete VPC $VPC..."
    if [[ ! -f "${VPC}assets.txt" ]]; then
        echo "Error, assets for VPC ${VPCID} not found, skipping..."
        continue
    fi
    . ${VPC}assets.txt

    vftrace "route table association to delete $ASSOCID"
    ec2 disassociate-route-table --association-id "${ASSOCID}"
    vftrace "\n"

    vftrace "destroy subnet 1 id $SN1ID ..."
    ec2 delete-subnet --subnet-id "$SN1ID"
    vftrace "\n"

    vftrace "destroy subnet 2 id $SN2ID ..."
    ec2 delete-subnet --subnet-id "$SN2ID"
    vftrace "\n"

    vftrace "route table to delete id $ROUTETABLEID ..."
    ec2 delete-route-table --route-table-id "${ROUTETABLEID}"
    vftrace "\n"

    vftrace "detach internet gateway from vpc..."
    ec2 detach-internet-gateway --internet-gateway-id "${IGWID}" --vpc-id $VPC
    vftrace "\n"

    vftrace "delete internet gateway to delete $IGWID"
    ec2 delete-internet-gateway --internet-gateway-id "${IGWID}"
    vftrace "\n"

    vftrace "delete vpc $VPC"
    ec2 delete-vpc --vpc-id $VPC
    vftrace "\n"
done

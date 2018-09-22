#!/bin/bash
#
# Script to build a VPC in AWS EC2
#
# 
# This follows Amazon's example for setting up an IPv4 VPC and subnets
# using the aws cli here :
# https://docs.aws.amazon.com/vpc/latest/userguide/vpc-subnets-commands-example.html
#

. tag.sh
if [[ -z "$VPCTAG" ]]; then
    echo "$0: Danger : please define your tag in tag.sh"
    exit
fi

. ./lib.sh


for i in "$@"; do
    case $i in
	-v)
	    VERBOSE=true
	    vftrace "verbose\n"
	    shift
	    ;;
	-c)
	    CHECK=true
	    vftrace "check\n"
	    shift
	    ;;
	-t|--tag)
	    INSTANCETAG="$2"
	    shift
	    shift
	    ;;	    
	*)
	    echo "unknown option $i"
	    usage
	    exit
	    ;;
    esac
done

vftrace "Check for aws cli...\n"
aws-check
jq-check
exists-check "${VPCTAG}"


if [[ -n "$CHECK" ]]; then
    vftrace "check only - exiting...\n"
    exit
fi

pid=$$
tempfilesdir="ec2-responses.${pid}"
mkdir $tempfilesdir
cd $tempfilesdir

vftrace "Create VPC..."
ec2 create-vpc --cidr-block 10.0.0.0/16 > vpc.details.json
vpcid=`cat vpc.details.json | jq -r '.Vpc.VpcId'`
vftrace "id = $vpcid\n"

tagit $vpcid
ASSETFILE="../${vpcid}assets.txt"

vftrace "Add first subnet..."
ec2 create-subnet --vpc-id "${vpcid}" --cidr-block 10.0.1.0/24 > subnet1.json
sn1=`cat subnet1.json | jq -r '.Subnet.SubnetId'`
echo "SN1ID=${sn1}" >> ${ASSETFILE}
vftrace "id = $sn1\n"

ec2 create-subnet --vpc-id "${vpcid}" --cidr-block 10.0.0.0/24 > subnet2.json
sn2=`cat subnet2.json | jq -r '.Subnet.SubnetId'`
echo "SN2ID=${sn2}" >> ${ASSETFILE}
vftrace "id = $sn2\n"

vftrace "Create gateway..."
ec2 create-internet-gateway > gw.json
gwid=`cat gw.json | jq -r '.InternetGateway.InternetGatewayId'`
echo "IGWID=${gwid}" >> ${ASSETFILE}
vftrace "id = $gwid\n"

vftrace "Attach gateway ..."
ec2 attach-internet-gateway --vpc-id "${vpcid}" --internet-gateway-id "${gwid}"
vftrace "\n"

vftrace "Create route table ..."
ec2 create-route-table      --vpc-id "${vpcid}" > route.table.json
route_tableid=`cat route.table.json | jq -r '.RouteTable.RouteTableId'`
echo "ROUTETABLEID=${route_tableid}" >> ${ASSETFILE}
vftrace "id = $route_tableid\n"

vftrace "Setup internet gateway route..."
ec2 create-route --route-table-id "${route_tableid}" --destination-cidr-block 0.0.0.0/0 --gateway-id "${gwid}" > create.route.json
vftrace "\n"

vftrace "Examining routes..."
ec2 describe-route-tables --route-table-id ${route_tableid} > route.tables.json
vftrace "\n"

vftrace "Examining subnets ..."
ec2 describe-subnets --filters "Name=vpc-id,Values=${vpcid}" --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock}' > subnets.json
publicid=`cat subnets.json | jq -r '.[] | .ID ' | head -1`
vftrace "public subnet id = ${publicid}\n"

vftrace "Associating routing table with public subnet..."
ec2 associate-route-table  --subnet-id "${publicid}" --route-table-id "${route_tableid}" > route-associations.json
publicrouteassociationid=`cat route-associations.json | jq -r '.AssociationId'`
echo "ASSOCID=${publicrouteassociationid}" >> ${ASSETFILE}
vftrace "public route association id = ${publicrouteassociationid}\n"

vftrace "Setting auto-ip"
ec2 modify-subnet-attribute --subnet-id "${publicid}" --map-public-ip-on-launch
vftrace "\n"
cd ..
vftrace "Listing all VPCs..."
ec2 describe-vpcs --filters Name=tag:vpctag,Values="${VPCTAG}"

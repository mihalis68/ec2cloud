#!/bin/bash
#
# Script to build a VPC in AWS EC2
#
. tag.sh
if [[ -z "$VPCTAG" ]]; then
    echo "Danger : please define your tag in tag.sh"
    exit
fi
VPCTAG="ChrisMorganVPC"
if [[ "$1" = "-v" ]]; then
    VERBOSE=true
fi
function vftrace() {
    if [[ ! -z "$VERBOSE" ]]; then
        printf "$@"
    fi
}
function apply_command() {
    "$@"
    RES=$?
    if [[ "$RES" -ne 0 ]]; then
        echo "Executing '$@' failed"
        exit $RES
    fi
}
function ec2() {
    apply_command aws ec2 "$@"
}
function tagit() {
    ec2 create-tags --resources "$1" --tags  Key=vpctag,Value="${VPCTAG}"
}

ASSETFILE="assets.txt"
touch $ASSETFILE

pid=$$
tempfilesdir="ec2-responses.${pid}"
mkdir $tempfilesdir
cd $tempfilesdir

vftrace "Create VPC..."

ec2 create-vpc --cidr-block 10.0.0.0/16 > vpc.details.json

vpcid=`cat vpc.details.json | jq -r '.Vpc.VpcId'`
vftrace "id = $vpcid\n"

tagit $vpcid

vftrace "Add subnets..."
ec2 create-subnet --vpc-id "${vpcid}" --cidr-block 10.0.1.0/24
ec2 create-subnet --vpc-id "${vpcid}" --cidr-block 10.0.0.0/24
vftrace "\n"

vftrace "Create gateway..."
ec2 create-internet-gateway > gw.json
gwid=`cat gw.json | jq -r '.InternetGateway.InternetGatewayId'`
vftrace "id = $gwid\n"

vftrace "Attach gateway ..."
ec2 attach-internet-gateway --vpc-id "${vpcid}" --internet-gateway-id "${gwid}"
vftrace "\n"

vftrace "Create route table ..."
ec2 create-route-table      --vpc-id "${vpcid}" > route.table.json
route_tableid=`cat route.table.json | jq -r '.RouteTable.RouteTableId'`
echo "ROUTETABLEID="${route_tableid}" > $ASSETFILE
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
ec2 associate-route-table  --subnet-id "${publicid}" --route-table-id "${route_tableid}"
vftrace "\n"

vftrace "Setting auto-ip"
ec2 modify-subnet-attribute --subnet-id "${publicid}" --map-public-ip-on-launch
vftrace "\n"
cd ..
ec2 describe-vpcs --filters Key=tag:vpctag,Value="${VPCTAG}"

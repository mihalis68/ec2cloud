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
function fatal() {
    echo "$0 : $1"
}
function ec2() {
    apply_command aws ec2 "$@"
}
function tagit() {
    ec2 create-tags --resources "$1" --tags  Key=vpctag,Value="${VPCTAG}"
}
function aws-check() {
    if [[ $(type -P aws) ]]; then
	vftrace "found executable aws in PATH\n"
	AWSVERS=`aws --version 2>&1`
	vftrace "aws version : ${AWSVERS}\n"
	AWSREG=`aws configure get region`
	vftrace "aws region  : ${AWSREG}\n"
    else
	echo "$0 : \"aws\" not found"
	exit
    fi
}
function jq-check() {
    if [[ $(type -P jq) ]]; then
	vftrace "found executable jq in PATH\n"
    else
	echo "$0 : \"jq\" not found"
	exit
    fi
}
function usage() {
    echo "Usage : "
    echo "      -v verbose"
    echo "      -c check-only"
}
function exists-check() {
    ec2 describe-vpcs --filters Name=tag:vpctag,Values="${VPCTAG}" --output text > vpcs.txt
    for VPC in `cat vpcs.txt | grep VPCS | awk '{print $7}'`; do
	echo "found $VPC, not creating"
	exit
    done
    echo "No VPCs matched tag ${VPCTAG}, building"
}

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

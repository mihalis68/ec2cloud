ec2cloud
========

A collection of scripts to build a VPC for experimenting with Amazon
EC2 instances in an isolated network. 


Flags
=====

Pass '-v' to build.sh and destroy.sh to get verbose output
Pass '-c' to only check credentials then exit

Pre-requisites
==============

The AWS CLI is expected to be available and active in the current
path. To check this, the script does a couple of read-only aws calls
as a test :

aws --version is expected to work
aws configure get region should show your version

Individual scripts
==================


* build.sh

Builds a VPC assuming you have your credentials setup and a tag
defined locally. Each VPC is tagged such that the destroy utility can
filter by tag to ensure it cannot touch any other VPC assets you may
have.

Successive invocations of build.sh will create additional VPCs up to
the VPC instances limit for your AWS account.

* destroy.sh

Deletes the assets created by build.sh assuming the temporary files
created by build.sh have been left around. This script will only find
VPCs according to the current tag set in tag.sh. This is a precaution
to avoid deleting unrelated VPCs in your account, for example your
default VPC, although it is likely such an attempt would fail if you
have any instances running there.

If the tag is changed and/or if you delete the temporary files created
by build.sh, you'll have to delete VPCs you wish to remove on the AWS
console. You can see and verify the tags of your VPCs to make sure you
don't delete anything else.

Note that destroy.sh currently tries to delete ALL VPCs with the tags
corresponding to tag.sh, that is if you invoke build.sh 5 times
successfully, you will have 5 VPCs, however destroy.sh would then only
need to be invoked once to delete all 5.

* lib.sh

shared bash functions

* clean-temp.sh

Remove all generated files from build.sh - this will prevent
destroy.sh from working so only run when you're cleaning everything
up.

* tag.sh

A sample tag setting. Uncomment the line and change the tag to match
your needs before trying to build.


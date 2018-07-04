ec2cloud
========

A collection of scripts to build a VPC for experimenting with Amazon
EC2 instances in an isolated network.

* build.sh

Builds a VPC assuming you have your credentials setup and a tag
defined locally. Each VPC is tagged such that the destory utility can
filter by tag to ensure it cannot touch any other VPC assets you may
have.

* destroy.sh

Deletes the assets created by build.sh assuming the temporary files
created by build.sh have been left around. If not you'll have to
delete the VPC on the AWS console. You can see and verify the tags of
your VPCs to make sure you don't delete anything else

* lib.sh

shared bash functions

* clean-temp.sh

Remove all generated files from build.sh - this will prevent
destroy.sh from working so only run when you're cleaning everything
up.

* tag.sh

A sample tag setting. Uncomment the line and change the tag to match
your needs before trying to build.

Flags
=====

use -v to build.sh and destroy.sh to get verbose output

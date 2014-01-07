#!/bin/sh -ex

install right_link_package/instance/LICENSE LICENSE
install -D right_link_package/instance/bin/ec2/wait_for_eip.rb bin/ec2/wait_for_eip.rb
install -D right_link_package/instance/bin/rackspace/wait_for_instance_ready.rb bin/rackspace/wait_for_instance_ready.rb
install -D right_link_package/instance/etc/init.d/rightscale_functions lib/rightscale_functions
install -D right_link_package/instance/etc/sudoers.d/rightscale etc/sudoers.d/rightscale
install -D right_link_package/instance/etc/sudoers.d/rightscale_users etc/sudoers.d/rightscale_users
install -D right_link_package/instance/etc/motd etc/motd
install -D right_link_package/instance/etc/motd-complete etc/motd-complete
install -D right_link_package/instance/etc/motd-failed etc/motd-failed

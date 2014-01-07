rightscale-control
==================

Scripts for system and service control of RightScale RightLink.

Upstream Files
--------------

Note: https://github.com/rightscale/right_link_package is not public.

These files are copied and updated from the upstream source:

/LICENSE                                    https://github.com/rightscale/right_link_package/blob/v5.9.5/instance/LICENSE
/bin/ec2/wait_for_eip.rb                    https://github.com/rightscale/right_link_package/blob/v5.9.5/instance/bin/ec2/wait_for_eip.rb
/bin/rackspace/wait_for_instance_ready.rb   https://github.com/rightscale/right_link_package/blob/v5.9.5/instance/bin/rackspace/wait_for_instance_ready.rb
/lib/rightscale_functions                   https://github.com/rightscale/right_link_package/blob/v5.9.5/instance/etc/init.d/rightscale_functions
/etc/sudoers.d/rightscale                   https://github.com/rightscale/right_link_package/blob/v5.9.5/instance/etc/sudoers.d/rightscale
/etc/sudoers.d/rightscale_users             https://github.com/rightscale/right_link_package/blob/v5.9.5/instance/etc/sudoers.d/rightscale_users
/etc/motd                                   https://github.com/rightscale/right_link_package/blob/v5.9.5/instance/etc/motd
/etc/motd-complete                          https://github.com/rightscale/right_link_package/blob/v5.9.5/instance/etc/motd-complete
/etc/motd-failed                            https://github.com/rightscale/right_link_package/blob/v5.9.5/instance/etc/motd-failed

To refresh:

 $ cd right_link_package
 $ git checkout v5.9.5
 $ cd .. && ./copy-upstream-files.sh

LICENSE
-------

See the LICENSE file.
#
# == Synopsis
#
# Wait for this machine's Elastic IP (EIP) to settle by querying a
# number of external observers to determine our public IP address.
#
# == Usage
#
# WaitFor
#      [ -v | --verbose                ]
#      [ -V | --Version                ]
#      [ -a | --all-example all | none ] (Default: none)
#      [ -h | --help                   ]
#
# == Author
# Edward M. Goldberg, RightScale Inc.
#
# == Copyright
# Copyright (c) 2008 RightScale, Inc, All Rights Reserved Worldwide.
#
# THIS PROGRAM IS CONFIDENTIAL AND PROPRIETARY TO RIGHTSCALE
# AND CONSTITUTES A VALUABLE TRADE SECRET.  Any unauthorized use,
# reproduction, modification, or disclosure of this program is
# strictly prohibited.  Any use of this program by an authorized
# licensee is strictly subject to the terms and conditions,
# including confidentiality obligations, set forth in the applicable
# License Agreement between RightScale.com, Inc. and
# the licensee.
#

# Rdoc related
require 'rubygems'
require 'optparse'

data_dir = "/var/spool/cloud"

begin
  require 'right_agent'
  data_dir = File.join(RightScale::Platform.filesystem.spool_dir, 'cloud')
rescue Exception => e
end


require File.join(data_dir, 'meta-data.rb')
require File.join(data_dir, 'user-data.rb')

class WaitFor
  def self.eip( eip, verbose=0 )

    if eip.nil?
      printf("No EIP, current IP=%s done...\n", ENV['EC2_PUBLIC_IPV4']);
      return
    end

    printf("Waiting for WAN IP address to be = %s\n\n",  eip) if verbose

    hosts = `dig +short eip-us-east.rightscale.com`.chomp.split

    if verbose
      printf("Using these hosts to check the EIP:\n")
      hosts.each { |host| printf("Host: %s\n", host) }
    end

    if verbose
      printf("-------------------------\n")
    end

    if hosts.length == 0
      printf("No hosts to use for the test.\n")
      return
    end

    timeout = 60 * 10 # We will spin for 10 min.  then just continue.
    pace    = 10      # Seconds for each poll
    vote    = 0
    majority = (hosts.length / 2)
    majority = 1 if majority < 2 # fix up numner for very small lists
    printf("Majority = %d\n", majority)

    while timeout > 0
      vote = 0
      printf("\nStart scan timeout = %d\n", timeout)

      for host in hosts
          address = `curl --max-time 1  -S -s http://#{host}/ip/mine`
          address = address.chomp  # watch out for extra stuff at the EOL

          if address == eip
            vote = vote + 1
            printf("Host: %s has settled Vote =%d\n", host, vote) if verbose
            return  if vote >  majority  # done if most say OK
          else
            printf("Host: %s return %s not %s keep waiting....\n", host, address, eip) if verbose
         end
       end

      timeout = timeout - pace
      timeout = 0 if timeout < 0  # catch that under-run error
      sleep pace if timeout > 0
    end

    if vote > 2
      printf("EIP %s has settled the wait is over.\n", eip)
    else
      printf("EIP %s never settled,  no servers ever reported a correct value.\n", eip)
    end

  end
end

#
# A request for HELP gets a printout and an exit code of ZERO
#
def usage(code=0)
  out = $0.split(' ')[0] + " usage:                                                          \n"
  out << "  [ -h | --help         ]                                                          \n"
  out << "  [ -l | --launched_eip ]   Wait for the eip defined at Server Launch              \n"
  out << "  [ -v | --verbose      ]                                                          \n"
  out << "  [ -V | --Version      ]                                                          \n"
  out << "  [ -e | --eip 1.2.3.4  ]    WaitFor this EIP to settle (default: Launch EIP)      \n"

  puts out
  exit(code)
end

#
# Default options
#
options = {
  :all     => "all",
  :path    => ENV['PATH'],
  :ps1     => ENV['PS1'],
  :EIP     => ENV['RS_EIP']
}

#
# Program Command Line Options
#
opts = OptionParser.new
opts.on("-h",  "--help")                      {      raise "Usage:"                           }
opts.on("-l",  "--launched_eip")              {      options[:EIP] = ENV['RS_EIP']            }
opts.on("-v",  "--verbose")                   {      options[:verbose] = TRUE                 }
opts.on("-V",  "--Version")                   {      puts "Version 1.0.0 " ; Kernel.exit(0)   }
opts.on("-e ", "--eip", String)               {|str| options[:EIP] = str                      }
opts.on("-a ", "--all",[:all,:none])          {|str| options[:all] = str                      }
opts.on("-f ", "--first",[:first,:all,:none]) {|str| options[:first] = str                    }

#
# Main Code
#
begin
  opts.parse(ARGV)
  WaitFor.eip(options[:EIP], verbose=options[:verbose] )

  # note that the ruby interpreter may or may not catch the exit exception in
  # the subsequent rescue statement, so avoid calling exit here.
  # exit(0)
rescue Exception => e
  puts e
  usage(-1) if e.to_s == "Usage:"
  exit(1)
end

exit(0)

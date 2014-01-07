#
# Copyright (c) 2012 RightScale Inc. All rights reserved.
#
# rackspace/fetch_userdata.rb: This script retrieves the Rackspace "user-data" and places
# it in /var/spool/rackspace/user-data.*
#
# Note that Rackspace doesn't support user data; by convention, we expect the user "data"
# to live in /var/spool/rackspace/user-data.txt and to be a set of name/value pairs delimited
# by the = character and separated by newlines.
#
# This file can be created using the boot-time file placement feature of the Rackspace API.
#
require 'rubygems'
require 'fileutils'
require 'json'
require 'right_agent'

module RightScale
  STATE_FILE_NAME       = 'instance_boot_state.js'
  SEED_DATA_DIR_NAME    = 'rackspace'
  USER_DATA_FILE_NAME   = 'user-data.txt'

  ROLES_KEY_PATH               = 'vm-data/provider_data/roles'
  RACK_CONNECT_STATUS_KEY_PATH = 'vm-data/user-metadata/rackconnect_automation_status'
  RACK_CONNECT_READY_STATE     = 'DEPLOYED'
  RACK_CONNECT_FAILED_STATE    = 'FAILED'

  MAX_WAIT_SECONDS = 15 * 60  # 15 minutes

  class WindowsSettings
    XEN_STORE_CLIENT_PATH  = 'c:\Program Files\Citrix\XenTools\xenstore_client.exe'
    SEED_FILE_NAME        = 'rightscale-A665E07B1FAC4d80A38FBB99E57B973E.txt'
    CACHE_DIR_NAME        = 'RightScaleCache'

    attr_accessor :output_dir, :seed_file, :user_data_file, :cache_dir, :state_file,
      :xen_store_read_cmd, :xen_store_list_cmd, :cached_seed_file

    def initialize(cloud_type)
      @xen_store_read_cmd    = "#{XEN_STORE_CLIENT_PATH} read"
      @xen_store_list_cmd    = "#{XEN_STORE_CLIENT_PATH} dir"

      @output_dir         = File.join(RightScale::Platform.filesystem.spool_dir, cloud_type)
      @seed_file          = File.join("c:", SEED_FILE_NAME)
      @user_data_file     = File.join(@output_dir, USER_DATA_FILE_NAME)
      @cache_dir          = File.join(app_data_dir, CACHE_DIR_NAME)

      # cache the personailty file and the current state file outside the
      # install path so they are available if RightLink is re-installed
      @cached_seed_file = File.join(@cache_dir, SEED_FILE_NAME)
      @state_file       = File.join(@cache_dir, STATE_FILE_NAME)
    end

    def is_initial_boot?
      !(state_file_exists? && cached_seed_file_exists?)
    end

    def is_reinstall?
      !user_data_exists? && state_file_exists? && cached_seed_file_exists?
    end

    def state_file_exists?
      File.exist?(@state_file)
    end

    def user_data_exists?
      File.exist?(@user_data_file)
    end

    private

    def app_data_dir
      win2k3_app_data = File.join(ENV['ALLUSERSPROFILE'], 'Application Data')
      win2k8_app_data = ENV['ALLUSERSPROFILE']
      if File.exists?(win2k3_app_data)
        win2k3_app_data
      else
        win2k8_app_data
      end
    end

    def cached_seed_file_exists?
      File.exist?(@cached_seed_file)
    end
  end

  class LinuxSettings
    XEN_STORE_CLIENT_PATH = '/usr/bin/xenstore'

    attr_accessor :output_dir, :seed_file, :user_data_file, :cache_dir, :state_file,
      :xen_store_read_cmd, :xen_store_list_cmd, :cached_seed_file

    def initialize(cloud_type)
      @xen_store_read_cmd    = "#{XEN_STORE_CLIENT_PATH}-read"
      @xen_store_list_cmd    = "#{XEN_STORE_CLIENT_PATH}-ls"

      # @output dir is a confusing variable name,
      # since the directory is really our input dir
      # (the cloud agent creates the dir and the files, and we read them).
      @output_dir         = File.join(RightScale::Platform.filesystem.spool_dir, 'rackspace')
      @seed_dir           = File.join(RightScale::Platform.filesystem.spool_dir, SEED_DATA_DIR_NAME)
      @cache_dir          = RightScale::Platform.filesystem.right_link_dynamic_state_dir
      @user_data_file     = File.join(@output_dir, USER_DATA_FILE_NAME)
      @seed_file          = File.join(@seed_dir, USER_DATA_FILE_NAME)
      @cached_seed_file   = nil
      @state_file         = File.join(@cache_dir, STATE_FILE_NAME)
    end

    def is_initial_boot?
      !state_file_exists?
    end

    def is_reinstall?
      false
    end

    def state_file_exists?
      File.exist?(@state_file)
    end

    def user_data_exists?
      File.exist?(@user_data_file)
    end
  end

  class RackspaceInitializer

    def initialize(cloud_type)
      if RightScale::Platform.windows?
        @settings = WindowsSettings.new(cloud_type)
      else
        @settings = LinuxSettings.new(cloud_type)
      end
    end

    def run
      # determine which type of boot this is
      state = determine_boot_state

      # need to wait for user data if this is an initial boot
      # Linux doen't used a cached seed file, so no need to copy it back
      if state == :rebundled_boot || state == :initial_boot
        wait_for_ready
        handle_user_data
      elsif state == :reinstall
        unless @settings.cached_seed_file.nil?
          FileUtils.cp(@settings.cached_seed_file, @settings.seed_file)
        end
        handle_user_data
      end
    end

    private

    def write_to_log(message)
      STDOUT.puts("#{Time.now.utc} #{message}")
    end

    def determine_boot_state
      # look for ready file
      slice_id_changed = false

      # compare the saved slice id and the slice id for this instance
      if @settings.state_file_exists?
        ready_state       = JSON::load(File.read(@settings.state_file))
        old_slice_id      = ready_state["slice_id"]
        current_slice_id  = find_slice_id
        slice_id_changed = (!current_slice_id.nil?) && current_slice_id.to_s != old_slice_id.to_s
      end

      # determine boot state
      if slice_id_changed
        write_to_log("Rebundled boot detected")
        state = :rebundled_boot
      elsif @settings.is_reinstall?
        write_to_log("Re-Install detected")
        state = :reinstall
      elsif @settings.is_initial_boot?
        write_to_log("Initial boot detected")
        state = :initial_boot
      else
        write_to_log("Reboot detected")
        state = :reboot
      end

      state
    end

    def wait_for_ready
      # determine if instance has a role which requires waiting.
      write_to_log("Querying instance roles...")
      stop_time = Time.now + MAX_WAIT_SECONDS  # time when we will stop checking
      roles_json = nil
      log_counter = 0
      while true
        roles_json = `#{@settings.xen_store_read_cmd} #{ROLES_KEY_PATH}`.strip
        break if $?.exitstatus == 0

        # check timeout
        if Time.now >= stop_time
          write_to_log("Timed out after #{MAX_WAIT_SECONDS} seconds.")
          break
        end

        # throttle repetitive logging to twice a minute.
        write_to_log("Waiting for xenstore call to succeed...") if 0 == (log_counter % 30)
        log_counter += 1
        sleep 1
      end
      log_counter = 0
      roles = JSON.load(roles_json) rescue nil
      roles = Array(roles)
      if roles.include?('rack_connect')
        # wait until the ready state is written to the xenstore
        write_to_log("Waiting for rack_connect instance to appear ready...")
        while true
          # read the status from xenstore
          status = `#{@settings.xen_store_read_cmd} #{RACK_CONNECT_STATUS_KEY_PATH}`.strip.gsub('"', '')
          if $?.exitstatus == 0
            # bail out when we see the expected status
            if 0 == status.casecmp(RACK_CONNECT_READY_STATE)
              write_to_log("Instance appears ready.")
              break
            end
            if 0 == status.casecmp(RACK_CONNECT_FAILED_STATE)
              write_to_log("Instance reported failure in status; attempting to continue.")
              break
            end

            # we are intentionally never timing out in this case.
            write_to_log("Waiting for rack_connect status to say deployed...") if 0 == (log_counter % 30)
          elsif Time.now >= stop_time
            write_to_log("Timed out after #{MAX_WAIT_SECONDS} seconds.")
            break
          else
            write_to_log("Waiting for query of automation status to succeed...") if 0 == (log_counter % 30)
          end
          log_counter += 1
          sleep 1
        end
      else
        write_to_log("Instance does not have rack_connect role; no waiting required.")
      end
      true
    ensure
      begin
        # always write state file when ready (whether or not we waited).
        FileUtils.mkdir_p(File.dirname(@settings.state_file))
        File.open(@settings.state_file, 'w+') {|f| f.write(JSON::dump({:slice_id => find_slice_id})) }
      rescue Exception => e
        write_to_log("Failed to write state file: #{e.class}: #{e.message}")
      end
    end

    def find_slice_id
      current_slice_id = nil

      # enumerate the network resources looking for the public interface
      networks = `#{@settings.xen_store_list_cmd} vm-data/networking`.split("\n")
      networks.each do |network_id|
        temp = network_id.split(" ").first
        network_string = `#{@settings.xen_store_read_cmd} vm-data/networking/#{temp}`
        network_info = JSON::parse(network_string)
        if network_info["label"] == "public"
          # the slice attribute is on the public network resource
          current_slice_id = network_info["slice"]
        end
      end

      current_slice_id
    end

    def handle_user_data
      # grab the personality file
      raw_data_file = @settings.seed_file
      raw_data_file_min_age_secs = 10
      raw_data_file_retry_delay_secs = 1

      write_to_log("Waiting for user data")

      waiting_for_raw_data = true
      wait_message = false
      while waiting_for_raw_data
        begin
          File.open(raw_data_file) do |f|
            # wait a reasonable time after file appears before reading it in case it is
            # still being deployed.
            now_time = Time.now
            raw_data_age = now_time - f.mtime()
            if raw_data_age >= raw_data_file_min_age_secs
              waiting_for_raw_data = false
            else
              write_to_log("Waiting for \"#{raw_data_file}\" to appear ready.")
              sleep(raw_data_file_min_age_secs - raw_data_age + 0.1)
            end
          end
        rescue
          # don't care why we failed to open file.
          unless wait_message
            write_to_log("Waiting for \"#{raw_data_file}\" to appear on disk.")
            wait_message = true
          end
          sleep raw_data_file_retry_delay_secs
        end
      end

      # ensure output user-data file exists.
      if File.exists?(raw_data_file)
        # create the user data file
        if raw_data_file != @settings.user_data_file
          FileUtils.mkdir_p(File.dirname(@settings.user_data_file))
          FileUtils.cp(raw_data_file, @settings.user_data_file)
        end

        # if a seed data file is available, then assume it is the user data and move it.
        # Linux doesn't use cached_seed_file, so don't execute if it's nil.
        if @settings.cached_seed_file
          # save the original personality file for future reference (on windows)
          FileUtils.mkdir_p(File.dirname(@settings.cached_seed_file))
          FileUtils.mv(raw_data_file, @settings.cached_seed_file)
        end
        write_to_log("User data saved")
      end
    end
  end
end

RightScale::RackspaceInitializer.new(ARGV[0] || 'rackspace').run

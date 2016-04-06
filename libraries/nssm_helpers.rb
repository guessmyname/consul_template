#
# Cookbook: consul_template
# License: MIT
#
# Copyright 2016, Vision Critical Inc.
#
# rubocop:disable Style/Documentation
require_relative './helpers'

module ConsulTemplateCookbook
  module NSSMHelpers
    include Chef::Mixin::ShellOut
    include ::ConsulTemplateCookbook::Helpers

    extend self

    def nssm_exe
      join_path(node['nssm']['install_location'], 'nssm.exe')
    end

    def nssm_params
      %w(Application
         AppParameters
         AppDirectory
         AppExit
         AppAffinity
         AppEnvironment
         AppEnvironmentExtra
         AppNoConsole
         AppPriority
         AppRestartDelay
         AppStdin
         AppStdinShareMode
         AppStdinCreationDisposition
         AppStdinFlagsAndAttributes
         AppStdout
         AppStdoutShareMode
         AppStdoutCreationDisposition
         AppStdoutFlagsAndAttributes
         AppStderr
         AppStderrShareMode
         AppStderrCreationDisposition
         AppStderrFlagsAndAttributes
         AppStopMethodSkip
         AppStopMethodConsole
         AppStopMethodWindow
         AppStopMethodThreads
         AppThrottle
         AppRotateFiles
         AppRotateOnline
         AppRotateSeconds
         AppRotateBytes
         AppRotateBytesHigh
         DependOnGroup
         DependOnService
         Description
         DisplayName
         ImagePath
         ObjectName
         Name
         Start
         Type)
    end

    def nssm_service_installed?
      # 1 is command not found
      # 3 is service not found
      exit_code = shell_out!(%("#{nssm_exe}" status consul-template), returns: [0, 1, 3]).exitstatus
      exit_code == 0 ? true : false
    end

    def new_version?(exe)
      path = shell_out(%("#{nssm_exe}" get consul-template Application)).stdout.delete("\0").strip
      path.eql?(exe) ? false : true
    end

    def nssm_service_status?(expected_status)
      expected_status.include? shell_out!(%("#{nssm_exe}" status consul-template), returns: [0]).stdout.delete("\0").strip
    end

    # Returns a hash of mismatched params
    def check_nssm_params
      # nssm can only get certain values
      params = node['consul_template']['service']['nssm_params'].select { |k, _v| nssm_params.include? k.to_s }
      params.each.each_with_object({}) do |(k, v), mismatch|
        # shell_out! returns values with null bytes, need to delete them before we evaluate
        unless shell_out!(%("#{nssm_exe}" get consul-template #{k}), returns: [0]).stdout.delete("\0").strip.eql? v.to_s
          mismatch[k] = v
        end
      end
    end
  end
end

Chef::Node.send(:include, ConsulTemplateCookbook::NSSMHelpers)

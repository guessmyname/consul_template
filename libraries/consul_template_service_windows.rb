#
# Cookbook: consul_template
# License: MIT
#
# Copyright 2016, Vision Critical Inc.
#
require 'poise'
require_relative './helpers'
require_relative './nssm_helpers'

module ConsulTemplateCookbook
  module Provider
    # A provider for managing the consul-template service on Windows.
    # @since 0.1.0
    class ConsulTemplateServiceWindows < Chef::Provider
      include Poise
      provides(:consul_template_service, os: %w(windows))
      include ::ConsulTemplateCookbook::Helpers
      include ::ConsulTemplateCookbook::NSSMHelpers

      def action_enable
        notifying_block do
          directories = %W(#{new_resource.data_dir}
                           #{::File.dirname(new_resource.nssm_params['AppStdout'])}
                           #{::File.dirname(new_resource.nssm_params['AppStderr'])}).uniq.compact
          directories.delete_if { |i| i.eql? '.' }.each do |dir|
            directory dir do
              recursive true
            end
          end

          nssm 'consul-template' do
            extend ::ConsulTemplateCookbook::NSSMHelpers
            action :install
            program new_resource.program
            parameters new_resource.nssm_params.select { |_k, v| v != '' }
            args new_resource.command
            not_if { nssm_service_installed? }
          end

          if nssm_service_installed?
            mismatch_params = check_nssm_params
            unless mismatch_params.empty?
              mismatch_params.each do |k, v|
                action = v.eql?('') ? "reset consul-template #{k}" : "set consul-template #{k} #{v}"
                batch "Set nssm parameter - #{k}" do
                  code "#{nssm_exe} #{action}"
                  notifies :run, 'powershell_script[Trigger consul-template restart]', :delayed
                end
              end

              batch 'Set nssm parameter - Application' do
                extend ::ConsulTemplateCookbook::NSSMHelpers
                code %(#{nssm_exe} set consul-template Application "#{new_resource.command}")
                only_if { new_version?(new_resource.command) }
                notifies :run, 'powershell_script[Trigger consul-template restart]', :delayed
              end

              powershell_script 'Trigger consul-template restart' do
                action :nothing
                code 'restart-service consul-template'
              end
            end
            # Check if the service is running, but don't bother if we're already
            # changing some nssm parameters
            powershell_script 'Trigger consul-template restart' do
              extend ::ConsulTemplateCookbook::NSSMHelpers
              code 'restart-service consul-template'
              not_if { nssm_service_status?(%w(SERVICE_RUNNING)) && mismatch_params.empty? }
            end
          end
        end
      end

      def action_reload
        notifying_block do
          powershell_script 'Restart consul-template' do
            code 'restart-service consul-template'
          end
        end
      end

      def action_restart
        notifying_block do
          powershell_script 'Restart consul-template' do
            code 'restart-service consul-template'
          end
        end
      end

      def action_disable
        notifying_block do
          # nssm resource doesn't stop the service before it removes it
          ps_stop_consul_template

          nssm 'consul-template' do
            action :remove
          end

          file new_resource.config_file do
            action :delete
          end
        end
      end
    end
  end
end

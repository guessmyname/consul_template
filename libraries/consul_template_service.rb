#
# Cookbook: consul_template
# License: MIT
#
# Copyright 2016, Vision Critical Inc.
#
require 'poise_service/service_mixin'
require_relative './helpers'

module ConsulTemplateCookbook
  module Resource
    # A `consul_template_service` resource for use with `poise_service`. This
    # resource manages the consul-template service.
    # @since 0.1.0
    class ConsulTemplateService < Chef::Resource
      include Poise
      provides(:consul_template_service)
      include PoiseService::ServiceMixin
      include ::ConsulTemplateCookbook::Helpers

      # @!attribute user
      # The service user the consul-template process runs as.
      # @return [String]
      attribute(:user, kind_of: String, default: lazy { node['consul_template']['service']['name'] })
      # @!attribute group
      # The service group the consul-template process runs as.
      # @return [String]
      attribute(:group, kind_of: String, default: lazy { node['consul_template']['service']['group'] })
      # @!attribute conf_dir
      # The path to the configuration directory on disk.
      # @return [String]
      attribute(:conf_dir, kind_of: String, default: lazy { node['consul_template']['config']['conf_dir'] })
      # @!attribute data_dir
      # The path in which the service will start in.
      # @return [String]
      attribute(:data_dir, kind_of: String, default: lazy { node['consul_template']['service']['data_dir'] })
      # @!attribute environment
      # The environment variables for the service (Linux only)
      # @return [String]
      attribute(:environment, kind_of: Hash, default: lazy { node['consul_template']['service']['environment'] })
      # @!attribute nssm_params
      # NSSM parameters, used by Windows clients only.
      # @return [String]
      attribute(:nssm_params, kind_of: Hash, default: lazy { node['consul_template']['service']['nssm_params'] })
      # @!attribute program
      # The location of the consul-template executable.
      # @return [String]
      attribute(:program, kind_of: String)

      def command
        if node.windows?
          %(-config "#{conf_dir}")
        else
          "#{program} -config #{conf_dir}"
        end
      end
    end
  end

  module Provider
    # A provider for managing the consul-template service.
    # @since 0.1.0
    class ConsulTemplateService < Chef::Provider
      include Poise
      provides(:consul_template_service)
      include PoiseService::ServiceMixin

      def action_enable
        notifying_block do
          directory new_resource.data_dir do
            recursive true
            owner new_resource.user
            group new_resource.group
            mode '0750'
          end
        end
        super
      end

      def service_options(service)
        service.command(new_resource.command)
        service.directory(new_resource.data_dir)
        service.user(new_resource.user)
        service.environment(new_resource.environment)
        service.restart_on_update(true)
        service.options(:systemd, template: 'consul_template:systemd.service.erb')
        service.options(:sysvinit, template: 'consul_template:sysvinit.service.erb')

        if node.platform_family?('rhel') && node.platform_version.to_i == 6
          service.provider(:sysvinit)
        end
      end
    end
  end
end

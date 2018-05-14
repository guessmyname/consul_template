#
# Cookbook: consul_template
# License: MIT
#
# Copyright 2016, Vision Critical Inc.
#
require 'poise'
require_relative './helpers'

module ConsulTemplateCookbook
  module Resource
    # A `consul_template` resource for creating consul templates
    # files.
    # @action create
    # @provides consul_template
    # @since 0.1.0
    class ConsulTemplate < Chef::Resource
      include Poise(fused: true)
      include ::ConsulTemplateCookbook::Helpers
      provides(:consul_template)
      actions(:create, :delete)
      default_action(:create)

      # @!attribute name
      # The name of the Consul Template configuration file
      # @return [String]
      attribute(:name, kind_of: String, name_attribute: true)
      # exposes source, cookbook, content, options attributes
      attribute(:templates, kind_of: Array, default: [])
      

      action(:create) do
        notifying_block do
          templates = new_resource.templates.map { |v| Mash.from_hash(v) }

          case node['consul_template']['init_style']
          when 'runit', 'systemd', 'upstart'
            consul_template_user = node['consul_template']['service']['user']
            consul_template_group = node['consul_template']['service']['group']
          else
            consul_template_user = 'root'
            consul_template_group = 'root'
          end

          # Create entries in configs-template dir but only if it's well formed
          templates.each_with_index do |v, i|
            raise "Missing source for #{i} entry at '#{new_resource.name}" if v[:source].nil?
            raise "Missing destination for #{i} entry at '#{new_resource.name}" if v[:destination].nil?
          end

          # Ensure config directory exists
          directory node['consul_template']['config']['conf_dir'] do
            unless node['platform'] == 'windows'
              user consul_template_user
              group consul_template_group
              mode 0o755
            end
            recursive true
            action :create
          end

          if node['platform'] == 'windows'
            template ::File.join(node['consul_template']['config']['conf_dir'], new_resource.name) do
              cookbook 'consul_template'
              source 'config-template-win.json.erb'
              variables(:templates => templates)
              not_if { templates.empty? }
            end
          else
            template ::File.join(node['consul_template']['config']['conf_dir'], new_resource.name) do
              cookbook 'consul_template'
              source 'config-template.json.erb'
              user consul_template_user
              group consul_template_group
              mode node['consul_template']['template_mode']
              variables(:templates => templates)
              not_if { templates.empty? }
            end
          end
        end  
      end

      action(:remove) do        
        notifying_block do
          file ::File.join(node['consul_template']['config']['conf_dir'], new_resource.name) do
            action :delete
          end
        end
      end
    end
  end
end

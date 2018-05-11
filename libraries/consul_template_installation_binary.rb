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
    # A `consul_template_installation` provider which manages consul-template binary
    # installation from remote source URL.
    # @action create
    # @action remove
    # @provides consul_template_installation
    # @example
    #   consul_template_installation '0.14.0'
    # @since 0.1.0
    class ConsulTemplateInstallationBinary < Chef::Provider
      include Poise(inversion: :consul_template_installation)
      include ::ConsulTemplateCookbook::Helpers
      include ::ConsulTemplateCookbook::NSSMHelpers

      provides(:binary)
      inversion_attribute('consul_template')

      # @api private
      def self.provides_auto?(_node, _resource)
        true
      end

      # Set the default inversion options.
      # @return [Hash]
      # @api private
      def self.default_inversion_options(node, new_resource)
        archive_basename = binary_basename(node, new_resource)
        url = node.archive_url % { version: new_resource.version, basename: archive_basename }
        super.merge(
          version: new_resource.version,
          archive_url: url,
          archive_basename: archive_basename,
          install_path: node.install_path
        )
      end

      def action_create
        archive_url = options[:archive_url] % {
          version: options[:version],
          basename: options[:archive_basename]
        }

        notifying_block do
          # Stop service if updating version (only on windows)
          ps_stop_consul_template if (windows? && !other_versions.empty?)
          # Remove any version that isn't the one we're using
          other_versions.each do |dir|
            directory "Remove version - #{dir}" do
              path dir
              action :delete
              recursive true
            end
          end

          directory join_path(options[:install_path], new_resource.version) do
            recursive true
          end

          poise_archive archive_url do
            destination  join_path(options[:install_path], new_resource.version) 
            strip_components 0
            not_if { ::File.exist?(program) }
          end          
        end
      end

      def action_remove
        notifying_block do
          directory join_path(options[:install_path], new_resource.version) do
            recursive true
            action :delete
          end
        end
      end

      def program
        @program ||= join_path(options[:install_path], new_resource.version, 'consul-template')
        windows? ? @program + '.exe' : @program
      end

      def self.binary_basename(node, resource)
        if node.arch_64?
          ['consul-template', resource.version, node['os'], 'amd64'].join('_')
        else
          ['consul-template', resource.version, node['os'], '386'].join('_')
        end.concat('.zip')
      end
      
    end
  end
end

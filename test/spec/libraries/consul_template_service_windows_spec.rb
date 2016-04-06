require_relative '../spec_helper'
require_relative '../../../libraries/consul_template_service'

describe ConsulTemplateCookbook::Resource::ConsulTemplateService do
  step_into(:consul_template_service)
  let(:chefspec_options) { { platform: 'windows', version: '2012R2' } }
  let(:shellout) { double('shellout') }

  before do
    allow(Mixlib::ShellOut).to receive(:new).and_return(shellout)
    allow(shellout).to receive(:live_stream)
    allow(shellout).to receive(:live_stream=)
    allow(shellout).to receive(:error!)
    allow(shellout).to receive(:stderr)
    allow(shellout).to receive(:run_command)
    allow(shellout).to receive(:exitstatus).and_return(0)
    allow(shellout).to receive(:stdout).and_return("consul-template v0.14.0\n")
  end

  recipe 'consul_template::default'

  it { expect(chef_run).to create_directory('C:\Program Files\consul-template\data') }
end

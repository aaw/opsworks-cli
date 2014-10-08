require 'spec_helper'

describe OpsWorks::CLI::Agent do
  describe '#deploy' do
    let(:app_name) { 'aptible' }
    let(:app) { Fabricate(:app, name: app_name) }

    let(:stacks) { 2.times.map { Fabricate(:stack) } }
    let(:deployment) { Fabricate(:deployment, status: 'successful') }

    before { allow(subject).to receive(:say) }
    before { allow(OpsWorks::Deployment).to receive(:wait) }
    before { allow(OpsWorks::Stack).to receive(:all) { stacks } }
    before { allow(OpsWorks::Stack).to receive(:active) { stacks } }

    before { stacks.each { |stack| allow(stack).to receive(:apps) { [app] } } }

    it 'should update custom cookbooks on all stacks' do
      expect(stacks[0]).to receive(:deploy_app).with(app) { deployment }
      expect(stacks[1]).to receive(:deploy_app).with(app) { deployment }
      subject.deploy(app_name)
    end

    it 'should not fail if some stacks are inactive' do
      allow(OpsWorks::Stack).to receive(:active) { [stacks[0]] }
      expect(stacks[0]).to receive(:deploy_app).with(app) { deployment }
      expect(stacks[1]).not_to receive(:deploy_app)
      subject.deploy(app_name)
    end

    it 'should optionally run on a subset of stacks' do
      expect(stacks[0]).to receive(:deploy_app).with(app) { deployment }
      expect(stacks[1]).not_to receive(:deploy_app)

      allow(subject).to receive(:options) { { stack: [stacks[0].name] } }
      subject.deploy(app_name)
    end

    it 'should not fail if a stack does not have the app' do
      allow(stacks[0]).to receive(:apps) { [] }
      expect(stacks[1]).to receive(:deploy_app).with(app) { deployment }
      expect { subject.deploy(app_name) }.not_to raise_error
    end

    it 'should fail if any update fails' do
      failure = Fabricate(:deployment, status: 'failed')
      expect(stacks[0]).to receive(:deploy_app).with(app) { failure }

      allow(subject).to receive(:options) { { stack: [stacks[0].name] } }
      expect { subject.deploy(app_name) }.to raise_error
    end
  end
end
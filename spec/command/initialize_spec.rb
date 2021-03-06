require 'spec_helper'

describe Claws::Command::Initialize do
  subject { Claws::Command::Initialize }

  let(:config) { 'test/.test.yml' }

  it 'creates the configuration file' do
    fh = double( File, :write => true )

    File.should_receive(:join).and_return(config)
    File.should_receive(:exists?).and_return(false)

    subject.should_receive(:print)

    File.should_receive(:open).with(config, 'w').and_return(fh)
    fh.should_receive(:write)

    subject.should_receive(:puts)
    subject.should_receive(:exit).with(0)

    subject.exec
  end

  it 'does not overwrite existing configuration file' do
    File.should_receive(:join).and_return(config)
    File.should_receive(:exists?).and_return(true)

    subject.should_receive(:puts)
    subject.should_receive(:exit).with(1)

    subject.exec
  end
end

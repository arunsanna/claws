require 'spec_helper'
require 'aws-sdk'
require 'claws/collection/ec2'

describe Claws::Collection::EC2 do
  subject { Claws::Collection::EC2 }

  let(:credentials) do
    {
      access_key_id: 'asdf',
      secret_access_key: 'qwer'
    }
  end

  let(:regions) do
    [
      double(
        'Aws::EC2::Region',
        name: 'us-east-1',
        instances: [double('Aws::EC2::Instance'), double('Aws::EC2::Instance')]
      ),
      double(
        'Aws::EC2::Region',
        name: 'eu-east-1',
        instances: [double('Aws::EC2::Instance'), double('Aws::EC2::Instance')]
      )
    ]
  end

  context 'gets all instances in regions' do
    it 'not defined in configuration' do
      allow(Aws).to receive_message_chain(:config, :update).with(credentials).and_return(true)

      expect(Aws::EC2).to receive(:new).and_return(
        double('Aws::EC2::RegionsCollection', regions: regions)
      )

      config = double(
        'Claws::Configuration',
        aws: credentials,
        ec2: OpenStruct.new(regions: nil)
      )

      expect(subject.new(config).get.size).to eq(4)
    end

    it 'defined in configuation' do
      allow(Aws).to receive_message_chain(:config, :update).with(credentials).and_return(true)

      allow(Aws::EC2).to receive(:new).and_return(
        double('Aws::EC2::RegionsCollection', regions: regions)
      )

      config = double(
        'Claws::Configuration',
        aws: credentials,
        ec2: OpenStruct.new(regions: %w[us-east-1 eu-east-1])
      )

      expect(subject.new(config).get.size).to eq(4)
    end
  end

  it 'gets all instances for specified regions' do
    allow(Aws).to receive_message_chain(:config, :update).with(credentials).and_return(true)

    expect(Aws::EC2).to receive(:new).and_return(
      double('Aws::EC2::RegionsCollection', regions: regions)
    )

    config = double(
      'Claws::Configuration',
      aws: credentials,
      ec2: OpenStruct.new(regions: %w[us-east-1])
    )

    expect(subject.new(config).get.size).to eq(2)
  end
end

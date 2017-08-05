require 'spec_helper'
require 'aws-sdk'
require 'claws/presenter/ec2'
require 'claws/capistrano'

describe Claws::EC2::Presenter do
  subject { Claws::EC2::Presenter }

  before :each do
    host = 'ec2-263-56-231-91.compute-1.amazonaws.com'

    full_instance = double('Aws::EC2',
      :public_dns => host,
      :security_groups => [
        double(Aws::EC2::SecurityGroup, :name => 'search', :id => 'sg-0f0f0f0f'),
        double(Aws::EC2::SecurityGroup, :name => 'mongo', :id => 'sg-0d0d0d0d'),
        double(Aws::EC2::SecurityGroup, :name => 'app', :id => 'sg-0c0c0c0c'),
      ],
      :tags => double(Aws::EC2::ResourceTagCollection, :select => [
          ['environment', 'production'],
          ['function', 'master'],
        ],
        'has_key?'.to_sym => true
      ),
      :elastic_ip => '11.111.111.111'
    )

    cap = double('Claws::Capistrano')
    cap.stub(:roles).with(host).and_return(%w{app web})

    @full_presenter = subject.new(full_instance, :region => 'us-east-1', :roles => cap.roles(full_instance.public_dns))

    less_instance = double(Aws::EC2, :tags => nil)
    @less_presenter = subject.new(less_instance)
  end

  describe '#initialize' do
    it 'requires a valid ec2 instance' do
      expect {
        subject.new
      }.to raise_exception ArgumentError
    end
  end

  describe '#region' do
    it 'can be defined' do
      @full_presenter.region.should == 'us-east-1'
    end

    it 'is not required' do
      @less_presenter.region.should == 'N/A'
    end
  end

  describe '#roles' do
    it 'can be defined' do
      @full_presenter.roles.should == 'app, web'
    end

    it 'are not required' do
      @less_presenter.roles.should == 'N/A'
    end
  end

  describe '#tags' do
    it 'present a string summary' do
      @full_presenter.tags.should == 'environment: production, function: master'
    end

    it 'are not required' do
      @less_presenter.tags.should == 'N/A'
    end
  end

  describe '#security_groups' do
    it 'presents summary of names' do
      @full_presenter.security_groups.should == 'sg-0f0f0f0f: search, sg-0d0d0d0d: mongo, sg-0c0c0c0c: app'
    end

    it 'are not required' do
      @less_presenter.security_groups.should == 'N/A'
    end
  end

  describe '#public_dns' do
    it 'displays when available' do
      @full_presenter.public_dns.should == 'ec2-263-56-231-91.compute-1.amazonaws.com'
    end

    it 'is not required' do
      @less_presenter.public_dns.should == 'N/A'
    end
  end

  describe '#elastic_ip' do
    it 'displays when available' do
      @full_presenter.elastic_ip.should == '11.111.111.111'
    end

    it 'is not required' do
      @less_presenter.elastic_ip.should == 'N/A'
    end
  end
end

require 'spec_helper'

describe Claws::Command::EC2 do
  subject { Claws::Command::EC2 }

  describe '#exec' do
    context 'configuration files' do
      let(:options) { OpenStruct.new(config_file: '/doesnotexist') }

      it 'missing files' do
        allow(subject).to receive(:puts).twice

        expect { subject.exec options }.to raise_exception Claws::ConfigurationError
      end

      it 'invalid file' do
        allow(YAML).to receive(:load_file).and_raise(Claws::ConfigurationError)

        allow(subject).to receive(:puts).twice

        expect { subject.exec options }.to raise_exception Claws::ConfigurationError
      end
    end

    context 'valid config file' do
      before :each do
        Claws::Configuration.stub(:new).and_return(
          OpenStruct.new(
            ssh: OpenStruct.new(user: 'test'),
            ec2: OpenStruct.new(fields: { id: { width: 10, title: 'ID' } })
          )
        )
      end

      let(:options) { OpenStruct.new(config_file: nil) }

      context 'instance collections' do
        it 'retrieves' do
          expect(Claws::Collection::EC2).to receive(:new).and_return(
            double(Claws::Collection::EC2, get: [double(Aws::EC2::Instance, id: 'test', status: 'running', dns_name: 'test.com')])
          )

          capture_stdout { subject.exec options }
        end

        it 'handles errors retrieving' do
          Claws::Collection::EC2.should_receive(:new).and_return(
            double(Claws::Collection::EC2, get: Exception.new)
          )

          # subject.should_receive(:puts).once

          expect { subject.exec options }.to raise_exception
        end
      end

      it 'performs report' do
        Claws::Collection::EC2.should_receive(:new).and_return(
          double(Claws::Collection::EC2, get: [double(Aws::EC2::Instance, id: 'test', status: 'running', dns_name: 'test.com')])
        )

        expect { capture_stdout { subject.exec options } }.to_not raise_exception
      end
    end

    context 'connect options' do
      let(:options) { OpenStruct.new(config_file: nil, connect: true) }

      before :each do
        Claws::Configuration.stub(:new).and_return(
          OpenStruct.new(
            ssh: OpenStruct.new(user: 'test', identity: 'my_id'),
            ec2: OpenStruct.new(fields: { id: { width: 10, title: 'ID' } })
          )
        )
      end

      context 'vpc' do
        let(:instances) do
          [
            double(Aws::EC2::Instance, id: 'test', status: 'running', private_ip_address: 'secret.com', vpc?: true)
          ]
        end

        it 'automatically connects to the server using private ip address' do
          Claws::Collection::EC2.should_receive(:new).and_return(
            double(Claws::Collection::EC2, get: instances)
          )

          subject.should_receive(:puts).twice
          subject.should_receive(:system).with('ssh -i my_id test@secret.com').and_return(0)

          capture_stdout { subject.exec options }
        end
      end

      context 'single instance' do
        let(:instances) { [double(Aws::EC2::Instance, id: 'test', status: 'running', dns_name: 'test.com', vpc?: false)] }

        it 'automatically connects to the server' do
          Claws::Collection::EC2.should_receive(:new).and_return(
            double(Claws::Collection::EC2, get: instances)
          )

          subject.should_receive(:puts).twice
          subject.should_receive(:system).with('ssh -i my_id test@test.com').and_return(0)

          capture_stdout { subject.exec options }
        end
      end

      context 'multiple instances' do
        let(:instances) do
          [
            double(Aws::EC2::Instance, id: 'test1', status: 'running', dns_name: 'test1.com', vpc?: false),
            double(Aws::EC2::Instance, id: 'test2', status: 'running', dns_name: 'test2.com', vpc?: false),
            double(Aws::EC2::Instance, id: 'test3', status: 'running', dns_name: 'test3.com', vpc?: false)
          ]
        end

        it 'handles user inputed selection from the command line' do
          Claws::Collection::EC2.should_receive(:new).and_return(
            double(Claws::Collection::EC2, get: instances)
          )

          subject.should_receive(:puts).twice
          subject.should_receive(:system).with('ssh -i my_id test@test2.com').and_return(0)

          capture_stdout { subject.exec OpenStruct.new(selection: 1, config_file: nil, connect: true) }
        end

        it 'presents a selection and connects to the server' do
          Claws::Collection::EC2.should_receive(:new).and_return(
            double(Claws::Collection::EC2, get: instances)
          )

          subject.should_receive(:gets).and_return('1\n')
          subject.should_receive(:puts).once
          subject.should_receive(:system).with('ssh -i my_id test@test2.com').and_return(0)

          capture_stdout { subject.exec options }
        end

        it 'presents a selection and allows a user to quit' do
          Claws::Collection::EC2.should_receive(:new).and_return(
            double(Claws::Collection::EC2, get: instances)
          )

          subject.should_receive(:gets).and_return('q\n')

          expect { capture_stdout { subject.exec options } }.to raise_exception SystemExit
        end
      end
    end
  end
end

require 'spec_helper'

RSpec.describe Sni::SysInfo do
  let(:service) { described_class.new }

  before do
    # Mock all system calls by default
    allow(service).to receive(:`).with('hostname').and_return("test-host\n")
    allow(service).to receive(:`).with('gem -v').and_return("3.4.19\n")
    allow(service).to receive(:`).with('bundler -v').and_return("Bundler version 2.7.0\n")
    allow(service).to receive(:`).with('env -i /usr/bin/passenger-config --version').and_return("Phusion Passenger 6.0.15\n")
    allow(ENV).to receive(:[]).with('HOSTNAME').and_return(nil)
  end

  describe '.call' do
    it 'returns a hash with system information' do
      result = described_class.call

      expect(result).to be_a(Hash)
      expect(result).to have_key(:host)
      expect(result).to have_key(:ruby)
      expect(result).to have_key(:rails)
      expect(result).to have_key(:gem)
      expect(result).to have_key(:bundler)
      expect(result).to have_key(:server)
      expect(result).to have_key(:env)
    end
  end

  describe '#call' do
    describe 'ruby_version' do
      it 'returns the Ruby version' do
        result = service.call
        expect(result[:ruby]).to eq(RUBY_VERSION)
      end
    end

    describe 'rails_version' do
      it 'returns the Rails version when Rails is defined' do
        rails_mock = double('Rails')
        allow(rails_mock).to receive(:version).and_return('7.0.0')
        allow(rails_mock).to receive(:env).and_return(double(production?: false, development?: false))
        stub_const('Rails', rails_mock)

        result = service.call
        expect(result[:rails]).to eq('7.0.0')
      end

      it 'returns N/A when Rails is not defined' do
        result = service.call
        expect(result[:rails]).to eq('N/A')
      end
    end

    describe 'gem_version' do
      it 'returns gem version from system command' do
        allow(service).to receive(:`).with('gem -v').and_return("3.7.0\n")

        result = service.call
        expect(result[:gem]).to eq('3.7.0')
      end

      it 'handles command failure gracefully' do
        allow(service).to receive(:`).with('gem -v').and_raise(StandardError.new('Command failed'))
        
        result = service.call
        expect(result[:gem]).to eq('unknown')
      end

      it 'handles unexpected format' do
        allow(service).to receive(:`).with('gem -v').and_return("3-7-0\n")

        result = service.call
        expect(result[:gem]).to eq('unexpected format')
      end
    end

    describe 'bundler_version' do
      it 'returns bundler version from system command' do
        allow(service).to receive(:`).with('bundler -v').and_return("Bundler version 2.7.0\n")

        result = service.call
        expect(result[:bundler]).to eq('2.7.0')
      end

      it 'handles command failure gracefully' do
        allow(service).to receive(:`).with('bundler -v').and_raise(StandardError.new('Command failed'))

        result = service.call
        expect(result[:bundler]).to eq('unknown')
      end

      it 'handles unexpected format' do
        allow(service).to receive(:`).with('bundler -v').and_return("2.7\n")

        result = service.call
        expect(result[:bundler]).to eq('unexpected format')
      end
    end

    describe 'hostname' do
      context 'when HOSTNAME env var is set' do
        it 'returns the HOSTNAME env var' do
          allow(ENV).to receive(:[]).with('HOSTNAME').and_return('test-host')

          result = service.call
          expect(result[:host]).to eq('test-host')
        end
      end

      context 'when HOSTNAME env var is not set' do
        before do
          allow(ENV).to receive(:[]).with('HOSTNAME').and_return(nil)
        end

        it 'returns hostname from system command' do
          allow(service).to receive(:`).with('hostname').and_return("my-host.local\n")

          result = service.call
          expect(result[:host]).to eq('my-host')
        end

        it 'handles command failure gracefully' do
          allow(service).to receive(:`).with('hostname').and_raise(StandardError.new('Command failed'))
          
          result = service.call
          expect(result[:host]).to eq('unknown')
        end
      end
    end

    describe 'server_version' do
      context 'in production environment' do
        before do
          rails_env = double(production?: true, development?: false)
          rails_mock = double('Rails', env: rails_env, version: '7.0.0')
          stub_const('Rails', rails_mock)
        end

        it 'returns passenger version' do
          allow(service).to receive(:`).with('env -i /usr/bin/passenger-config --version').and_return('Phusion Passenger 6.0.15')

          result = service.call
          expect(result[:server]).to eq('Passenger 6.0.15')
        end

        it 'handles passenger command failure' do
          allow(service).to receive(:`).with('env -i /usr/bin/passenger-config --version').and_raise(StandardError.new('Command failed'))
          
          result = service.call
          expect(result[:server]).to eq('unknown')
        end

        it 'handles unexpected format' do
          allow(service).to receive(:`).with('env -i /usr/bin/passenger-config --version').and_return("6.0.a\n")

          result = service.call
          expect(result[:server]).to eq('unexpected format')
        end
      end

      context 'in development environment' do
        before do
          rails_env = double(production?: false, development?: true)
          rails_mock = double('Rails', env: rails_env, version: '7.0.0')
          stub_const('Rails', rails_mock)
        end

        it 'returns puma version when Puma is defined' do
          # Create a proper nested constant structure
          const_module = Module.new
          const_module.const_set(:VERSION, '5.6.4')
          puma_module = Module.new  
          puma_module.const_set(:Const, const_module)
          stub_const('Puma', puma_module)
          
          result = service.call
          expect(result[:server]).to eq('Puma 5.6.4')
        end

        it 'returns N/A when Puma is not defined' do
          result = service.call
          expect(result[:server]).to eq('N/A')
        end
      end

      context 'in other environments' do
        it 'returns N/A' do
          rails_env = double(production?: false, development?: false)
          rails_mock = double('Rails', env: rails_env, version: '7.0.0')
          stub_const('Rails', rails_mock)

          result = service.call
          expect(result[:server]).to eq('N/A')
        end
      end
    end

    describe 'environment' do
      context 'when Rails is defined' do
        it 'returns the Rails environment' do
          rails_env = double(production?: false, development?: false)
          rails_mock = double('Rails', env: rails_env, version: '7.0.0')
          allow(rails_env).to receive(:to_s).and_return('test')
          stub_const('Rails', rails_mock)

          result = service.call
          expect(result[:env]).to eq('test')
        end
      end

      context 'when Rails is not defined' do
        it 'returns N/A' do
          result = service.call
          expect(result[:env]).to eq('N/A')
        end
      end
    end
  end
end

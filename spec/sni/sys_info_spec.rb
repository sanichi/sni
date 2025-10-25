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
    allow(ENV).to receive(:[]).with('USER').and_return('sanichi')
    allow(ENV).to receive(:[]).with('SHELL').and_return('/bin/bash')
    allow(ENV).to receive(:[]).with('PWD').and_return('/var/www/mio/current')
    allow(ENV).to receive(:[]).with('PATH').and_return('/usr/bin:/usr/sbin')
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
      expect(result).to have_key(:postgres)
      expect(result).to have_key(:user)
      expect(result).to have_key(:shell)
      expect(result).to have_key(:pwd)
      expect(result).to have_key(:path)
    end
  end

  describe '#call' do
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

    describe 'postgres_version' do
      context 'when ActiveRecord is defined' do
        let(:connection) { double('connection') }
        let(:result) { double('result', values: [['PostgreSQL 14.5 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.4.7 20120313 (Red Hat 4.4.7-18), 64-bit']]) }

        before do
          active_record_base = double('ActiveRecord::Base')
          allow(active_record_base).to receive(:connection).and_return(connection)
          stub_const('ActiveRecord::Base', active_record_base)
        end

        it 'returns postgres version when connection succeeds' do
          allow(connection).to receive(:execute).with('select version();').and_return(result)

          result = service.call
          expect(result[:postgres]).to eq('14.5')
        end

        it 'handles connection failure gracefully' do
          allow(connection).to receive(:execute).with('select version();').and_raise(StandardError.new('Connection failed'))

          result = service.call
          expect(result[:postgres]).to eq('unknown')
        end

        it 'handles unexpected version format' do
          unexpected_result = double('result', values: [['MySQL 8.0.30']])
          allow(connection).to receive(:execute).with('select version();').and_return(unexpected_result)

          result = service.call
          expect(result[:postgres]).to eq('unexpected format')
        end

        it 'handles different postgres versions' do
          postgres_15_result = double('result', values: [['PostgreSQL 15.2 on x86_64-pc-linux-gnu']])
          allow(connection).to receive(:execute).with('select version();').and_return(postgres_15_result)

          result = service.call
          expect(result[:postgres]).to eq('15.2')
        end
      end

      context 'when ActiveRecord is not defined' do
        it 'returns N/A' do
          result = service.call
          expect(result[:postgres]).to eq('N/A')
        end
      end
    end

    describe 'user' do
      it 'returns the USER environment variable when set' do
        allow(ENV).to receive(:[]).with('USER').and_return('sanichi')

        result = service.call
        expect(result[:user]).to eq('sanichi')
      end

      it 'returns unknown when USER environment variable is not set' do
        allow(ENV).to receive(:[]).with('USER').and_return(nil)

        result = service.call
        expect(result[:user]).to eq('unknown')
      end
    end

    describe 'shell' do
      it 'returns the SHELL environment variable when set' do
        allow(ENV).to receive(:[]).with('SHELL').and_return('/bin/bash')

        result = service.call
        expect(result[:shell]).to eq('/bin/bash')
      end

      it 'returns unknown when SHELL environment variable is not set' do
        allow(ENV).to receive(:[]).with('SHELL').and_return(nil)

        result = service.call
        expect(result[:shell]).to eq('unknown')
      end
    end

    describe 'pwd' do
      it 'returns the PWD environment variable when set' do
        allow(ENV).to receive(:[]).with('PWD').and_return('/var/www/mio/current')

        result = service.call
        expect(result[:pwd]).to eq('/var/www/mio/current')
      end

      it 'returns unknown when PWD environment variable is not set' do
        allow(ENV).to receive(:[]).with('PWD').and_return(nil)

        result = service.call
        expect(result[:pwd]).to eq('unknown')
      end
    end

    describe 'path' do
      it 'returns the PATH environment variable as comma-separated list' do
        allow(ENV).to receive(:[]).with('PATH').and_return('/usr/bin:/usr/sbin:/bin')

        result = service.call
        expect(result[:path]).to eq('/usr/bin, /usr/sbin, /bin')
      end

      it 'simplifies /Users/username paths to ~ notation' do
        path_value = '/Users/mjo/.rbenv/versions/3.4.5/bin:/Users/mjo/.rbenv/shims:/opt/homebrew/bin'
        allow(ENV).to receive(:[]).with('PATH').and_return(path_value)

        result = service.call
        expect(result[:path]).to eq('~/.rbenv/versions/3.4.5/bin, ~/.rbenv/shims, /opt/homebrew/bin')
      end

      it 'simplifies /home/username paths to ~ notation' do
        path_value = '/home/user/.local/bin:/usr/bin'
        allow(ENV).to receive(:[]).with('PATH').and_return(path_value)

        result = service.call
        expect(result[:path]).to eq('~/.local/bin, /usr/bin')
      end

      it 'returns single path as-is' do
        allow(ENV).to receive(:[]).with('PATH').and_return('/usr/bin')

        result = service.call
        expect(result[:path]).to eq('/usr/bin')
      end

      it 'returns empty string for empty PATH' do
        allow(ENV).to receive(:[]).with('PATH').and_return('')

        result = service.call
        expect(result[:path]).to eq('')
      end

      it 'returns unknown when PATH environment variable is not set' do
        allow(ENV).to receive(:[]).with('PATH').and_return(nil)

        result = service.call
        expect(result[:path]).to eq('unknown')
      end

      it 'handles path processing failure gracefully' do
        allow(ENV).to receive(:[]).with('PATH').and_return('/usr/bin')
        allow(service).to receive(:simplify_home_path).and_raise(StandardError.new('Processing failed'))

        result = service.call
        expect(result[:path]).to eq('unknown')
      end
    end
  end
end

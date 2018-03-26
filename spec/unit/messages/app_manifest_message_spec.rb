require 'spec_helper'
require 'messages/app_manifest_message'

module VCAP::CloudController
  RSpec.describe AppManifestMessage do
    describe 'validations' do
      context 'when unexpected keys are requested' do
        let(:params) { { instances: 3, memory: '2G', name: 'foo' } }

        it 'is valid' do
          message = AppManifestMessage.new(params)

          expect(message).to be_valid
        end
      end

      describe 'memory' do
        context 'when memory unit is not part of expected set of values' do
          let(:params) { { memory: '200INVALID' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Memory must use a supported unit: B, K, KB, M, MB, G, GB, T, or TB')
          end
        end

        context 'when memory is not a positive amount' do
          let(:params) { { memory: '-1MB' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Memory must be greater than 0MB')
          end
        end

        context 'when memory is in bytes' do
          let(:params) { { memory: '-35B' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Memory must be greater than 0MB')
          end
        end
      end

      describe 'disk_quota' do
        context 'when disk_quota unit is not part of expected set of values' do
          let(:params) { { disk_quota: '200INVALID' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Disk quota must use a supported unit: B, K, KB, M, MB, G, GB, T, or TB')
          end
        end

        context 'when disk_quota is not a positive amount' do
          let(:params) { { disk_quota: '-1MB' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Disk quota must be greater than 0MB')
          end
        end

        context 'when disk_quota is not numeric' do
          let(:params) { { disk_quota: 'gerg herscheiser' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Disk quota is not a number')
          end
        end
      end

      describe 'buildpack' do
        context 'when providing a valid buildpack name' do
          let(:buildpack) { Buildpack.make }
          let(:params) { { buildpack: buildpack.name } }

          it 'is valid' do
            message = AppManifestMessage.new(params)

            expect(message).to be_valid
          end
        end

        context 'when the buildpack is not a string' do
          let(:params) { { buildpack: 99 } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Buildpacks can only contain strings')
          end
        end
      end

      describe 'stack' do
        context 'when providing a valid stack name' do
          let(:params) { { stack: 'cflinuxfs2' } }

          it 'is valid' do
            message = AppManifestMessage.new(params)

            expect(message).to be_valid
            expect(message.stack).to eq('cflinuxfs2')
          end
        end

        context 'when the stack is not a string' do
          let(:params) { { stack: 99 } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Stack must be a string')
          end
        end
      end

      describe 'instances' do
        context 'when instances is not an number' do
          let(:params) { { instances: 'silly string thing' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Instances is not a number')
          end
        end

        context 'when instances is not an integer' do
          let(:params) { { instances: 3.5 } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Instances must be an integer')
          end
        end

        context 'when instances is not a positive integer' do
          let(:params) { { instances: -1 } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Instances must be greater than or equal to 0')
          end
        end
      end

      describe 'env' do
        context 'when env is not a hash' do
          let(:params) do
            {
              env: 'im a non-hash'
            }
          end
          it 'is not valid' do
            message = AppManifestMessage.new(params)
            expect(message).to_not be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('env must be a hash of keys and values')
          end
        end

        context 'when env has bad keys' do
          let(:params) do
            {
              env: {
                "": 'null-key',
                VCAP_BAD_KEY: 1,
                VMC_BAD_KEY: %w/hey it's an array/,
                PORT: 5,
              }
            }
          end
          it 'is not valid' do
            message = AppManifestMessage.new(params)
            expect(message).to_not be_valid
            expect(message.errors.count).to eq(4)
            expect(message.errors.full_messages).to match_array([
              'Env cannot set PORT',
              'Env cannot start with VCAP_',
              'Env cannot start with VMC_',
              'Env key must be a minimum length of 1'])
          end
        end
      end

      context 'when there are multiple errors' do
        let(:params) do
          {
            instances: -1,
            memory: 120,
            disk_quota: '-120KB',
            buildpack: 99,
            stack: 42,
            env: %w/not a hash/
          }
        end

        it 'is not valid' do
          message = AppManifestMessage.new(params)

          expect(message).not_to be_valid
          expect(message.errors.count).to eq(6)
          expect(message.errors.full_messages).to match_array([
            'Instances must be greater than or equal to 0',
            'Memory must use a supported unit: B, K, KB, M, MB, G, GB, T, or TB',
            'Disk quota must be greater than 0MB',
            'Buildpacks can only contain strings',
            'Stack must be a string',
            'env must be a hash of keys and values',
          ])
        end
      end
    end

    describe '.create_from_http_request' do
      let(:parsed_yaml) { { 'name' => 'blah', 'instances' => 4, 'memory' => '200GB' } }

      it 'returns the correct AppManifestMessage' do
        message = AppManifestMessage.create_from_http_request(parsed_yaml)

        expect(message).to be_valid
        expect(message).to be_a(AppManifestMessage)
        expect(message.instances).to eq(4)
        expect(message.memory).to eq('200GB')
      end

      it 'converts requested keys to symbols' do
        message = AppManifestMessage.create_from_http_request(parsed_yaml)

        expect(message.requested?(:instances)).to be_truthy
        expect(message.requested?(:memory)).to be_truthy
      end
    end

    describe '#process_scale_message' do
      let(:parsed_yaml) { { 'disk_quota' => '1000GB', 'memory' => '200GB', instances: 5 } }

      it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
        message = AppManifestMessage.create_from_http_request(parsed_yaml)

        expect(message.manifest_process_scale_message.instances).to eq(5)
        expect(message.manifest_process_scale_message.memory).to eq(204800)
        expect(message.manifest_process_scale_message.disk_quota).to eq(1024000)
      end

      context 'it handles bytes' do
        let(:parsed_yaml) { { 'disk_quota' => '7340032B', 'memory' => '3145728B', instances: 8 } }

        it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)
          expect(message).to be_valid
          expect(message.manifest_process_scale_message.instances).to eq(8)
          expect(message.manifest_process_scale_message.memory).to eq(3)
          expect(message.manifest_process_scale_message.disk_quota).to eq(7)
        end
      end

      context 'it handles exactly 1MB' do
        let(:parsed_yaml) { { 'disk_quota' => '1048576B', 'memory' => '1048576B', instances: 8 } }

        it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)
          expect(message).to be_valid
          expect(message.manifest_process_scale_message.instances).to eq(8)
          expect(message.manifest_process_scale_message.memory).to eq(1)
          expect(message.manifest_process_scale_message.disk_quota).to eq(1)
        end
      end

      context 'it complains about 1MB - 1' do
        let(:parsed_yaml) { { 'disk_quota' => '1048575B', 'memory' => '1048575B', instances: 8 } }

        it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)
          expect(message).not_to be_valid
          expect(message.errors.count).to eq(2)
          expect(message.errors.full_messages).to match_array(['Memory must be greater than 0MB', 'Disk quota must be greater than 0MB'])
        end
      end

      context 'when attributes are not requested in the manifest' do
        let(:parsed_yaml) { {} }

        it 'does not forward missing attributes to the ManifestProcessScaleMessage' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)

          expect(message.process_scale_message.requested?(:instances)).to be false
          expect(message.process_scale_message.requested?(:memory)).to be false
          expect(message.process_scale_message.requested?(:disk_quota)).to be false
        end
      end
    end

    describe '#app_update_message' do
      let(:buildpack) { VCAP::CloudController::Buildpack.make }
      let(:stack) { VCAP::CloudController::Stack.make }
      let(:parsed_yaml) { { 'buildpack' => buildpack.name, 'stack' => stack.name } }

      it 'returns an AppUpdateMessage containing mapped attributes' do
        message = AppManifestMessage.create_from_http_request(parsed_yaml)

        expect(message.app_update_message.buildpack_data.buildpacks).to include(buildpack.name)
        expect(message.app_update_message.buildpack_data.stack).to eq(stack.name)
      end

      context 'when attributes are not requested in the manifest' do
        context 'when no lifecycle data is requested in the manifest' do
          let(:parsed_yaml) { {} }

          it 'does not forward missing attributes to the AppUpdateMessage' do
            message = AppManifestMessage.create_from_http_request(parsed_yaml)

            expect(message.app_update_message.requested?(:lifecycle)).to be false
          end
        end

        context 'when stack is not requested in the manifest but buildpack is requested' do
          let(:parsed_yaml) { { 'buildpack' => buildpack.name } }

          it 'does not forward missing attributes to the AppUpdateMessage' do
            message = AppManifestMessage.create_from_http_request(parsed_yaml)

            expect(message.app_update_message.requested?(:lifecycle)).to be true
            expect(message.app_update_message.buildpack_data.requested?(:buildpacks)).to be true
            expect(message.app_update_message.buildpack_data.requested?(:stack)).to be false
          end
        end

        context 'when buildpack is not requested in the manifest but stack is requested' do
          let(:parsed_yaml) { { 'stack' => stack.name } }

          it 'does not forward missing attributes to the AppUpdateMessage' do
            message = AppManifestMessage.create_from_http_request(parsed_yaml)

            expect(message.app_update_message.requested?(:lifecycle)).to be true
            expect(message.app_update_message.buildpack_data.requested?(:buildpacks)).to be false
            expect(message.app_update_message.buildpack_data.requested?(:stack)).to be true
          end
        end
      end

      context 'when it specifies a "default" buildpack' do
        let(:parsed_yaml) { { buildpack: 'default' } }
        it 'updates the buildpack_data to be an empty array' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)
          expect(message.app_update_message.buildpack_data.buildpacks).to be_empty
        end
      end

      context 'when it specifies a null buildpack' do
        let(:parsed_yaml) { { buildpack: nil } }
        it 'updates the buildpack_data to be an empty array' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)
          expect(message.app_update_message.buildpack_data.buildpacks).to be_empty
        end
      end
    end

    describe '#process_update_message' do
      let(:parsed_yaml) do
        { command: command }
      end

      context 'when a new command is specified' do
        let(:command) { 'new-command' }

        it 'sets the command field in the message' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)
          expect(message).to be_valid
          expect(message.manifest_process_update_message.command).to eq('new-command')
        end
      end

      context 'when a string command of value "null" is specified' do
        let(:command) { 'null' }

        it 'does not set the command field in the process update message' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)
          expect(message).to be_valid
          expect(message.manifest_process_update_message.command).to eq('null')
        end
      end

      # This happens when users specify `command: ` with no value in the manifest.
      context 'when a nil command (value nil) is specified' do
        let(:command) { nil }

        it 'sets the field as null in the process update message' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)
          expect(message).to be_valid
          expect(message.manifest_process_update_message.command).to eq('null')
        end
      end

      context 'when a default command is specified' do
        let(:command) { 'default' }

        it 'does not set the command field in the process update message' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)
          expect(message).to be_valid
          expect(message.manifest_process_update_message.command).to eq('default')
        end
      end

      context 'when an empty command is specified' do
        let(:command) { '' }

        it 'is not valid' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)
          expect(message).not_to be_valid
          expect(message.errors.count).to eq(1)
          expect(message.errors.full_messages).to include('Command must be between 1 and 4096 characters')
        end
      end

      context 'when no command is specified' do
        let(:parsed_yaml) do
          {}
        end

        it 'does not set a command field' do
          message = AppManifestMessage.create_from_http_request(parsed_yaml)
          expect(message).to be_valid
          expect(message.manifest_process_update_message.requested?(:command)).to be_falsey
        end
      end
    end
  end
end

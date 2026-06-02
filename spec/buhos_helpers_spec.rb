require 'spec_helper'
require 'tmpdir'

describe Buhos::Helpers do
  let(:helper) { Class.new { extend Buhos::Helpers } }

  around do |example|
    previous_env = ENV[Buhos::Helpers::FILES_DIR_ENV_KEY]
    ENV.delete(Buhos::Helpers::FILES_DIR_ENV_KEY)

    example.run
  ensure
    previous_env.nil? ? ENV.delete(Buhos::Helpers::FILES_DIR_ENV_KEY) : ENV[Buhos::Helpers::FILES_DIR_ENV_KEY] = previous_env
  end

  describe '#dir_files' do
    it 'uses the legacy test fallback when no files directory is configured' do
      expect(helper.dir_files).to eq(File.expand_path('spec/usr/files', helper.dir_base))
    end

    it 'uses BUHOS_FILES_DIR as an absolute directory' do
      Dir.mktmpdir do |dir|
        ENV['BUHOS_FILES_DIR'] = dir

        expect(helper.dir_files).to eq(dir)
      end
    end

    it 'resolves a relative BUHOS_FILES_DIR from the application root' do
      ENV['BUHOS_FILES_DIR'] = 'tmp/custom_ifiles'

      expect(helper.dir_files).to eq(File.expand_path('tmp/custom_ifiles', helper.dir_base))
    ensure
      FileUtils.rm_rf(File.expand_path('tmp/custom_ifiles', helper.dir_base))
    end

  end
end

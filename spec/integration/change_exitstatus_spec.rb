require 'English'
require 'rspec/bash'

describe 'Change exitstatus' do
  include Rspec::Bash
  let(:stubbed_env) { create_stubbed_env }
  let!(:command1_stub) { stubbed_env.stub_command('command1') }
  let(:script) do
    <<-SCRIPT
      command1 "foo bar"
    SCRIPT
  end
  let(:script_path) { Pathname.new '/tmp/test_script.sh' }

  before do
    script_path.open('w') { |f| f.puts script }
    script_path.chmod 0777
  end

  after do
    script_path.delete
  end

  describe 'default exitstatus' do
    it 'is 0' do
      output, error, status = stubbed_env.execute script_path.to_s
      expect(status.exitstatus).to eq 0
    end
  end

  describe 'changing exitstatus' do
    before do
      command1_stub.returns_exitstatus(4)
    end

    it 'returns the stubbed exitstatus' do
      output, error, status = stubbed_env.execute script_path.to_s
      expect(status.exitstatus).to eq 4
    end

    context 'with specific args only' do
      before do
        command1_stub.with_args('foo bar').returns_exitstatus(2)
        command1_stub.with_args('bar').returns_exitstatus(6)
      end

      it 'returns the stubbed exitstatus' do
        output, error, status = stubbed_env.execute script_path.to_s
        expect(status.exitstatus).to eq 2
      end
    end
  end
end

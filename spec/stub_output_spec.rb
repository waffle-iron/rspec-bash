require 'English'
require 'rspec/shell/expectations'

describe 'Stub command output' do
  include Rspec::Shell::Expectations
  let(:stubbed_env) { create_stubbed_env }
  let!(:command1_stub) { stubbed_env.stub_command('command1') }

  let(:script) do
    <<-SCRIPT
      command1
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

  describe 'stubbing standard-out' do
    subject do
      stubbed_env.execute "#{script_path} 2>/dev/null"
    end

    it 'changes standard-out' do
      command1_stub.outputs('hello', to: :stdout)
      o, e, _s = subject
      expect(o).to eql 'hello'
      expect(e).to be_empty
    end
  end

  describe 'stubbing standard-err' do
    subject do
      stubbed_env.execute "#{script_path} 1>/dev/null"
    end

    it 'changes standard-out' do
      command1_stub.outputs('world', to: :stderr)
      o, e, _s = subject
      expect(e).to eql "world\n"
      expect(o).to be_empty
    end
  end

  describe 'stubbing contents to file' do
    subject do
      stubbed_env.execute "#{script_path}"
    end
    let(:filename) { 'test-log.nice' }
    after do
      f = Pathname.new(filename)
      f.delete if f.exist?
    end

    it 'write data to a file' do
      command1_stub.outputs('world', to: filename)
      o, e, _s = subject
      expect(e).to be_empty
      expect(o).to be_empty
      expect(Pathname.new(filename).read).to eql 'world'
    end

    describe 'using passed argument as filename' do
      let(:script) do
        <<-SCRIPT
          command1 input output
        SCRIPT
      end

      let(:passed_filename) { ['hello-', :arg2, '.foo'] }
      let(:filename) { 'hello-output.foo' }

      it 'writes data to an interpolated filename' do
        command1_stub.outputs('world', to: passed_filename)
        subject
        expect(Pathname.new(filename).read).to eql 'world'
      end
    end
  end

  describe 'stubbing commands with arguments passed to stdout' do
    subject do
      stubbed_env.execute "#{script_path}"
    end
    
    let(:script) do
      <<-SCRIPT
        command1 input output
      SCRIPT
    end

    it 'outputs correctly when all arguments match' do
      command1_stub.with_args('input', 'output').outputs('world', to: :stdout)
      o, e, _s = subject
      expect(e).to be_empty
      expect(o).to eql 'world'
    end

    it 'does not output when called with extra arguments, even if some match' do
      command1_stub.with_args('input', 'output', 'anything').outputs('arbitrary string', to: :stdout)
      o, e, _s = subject
      expect(e).to be_empty
      expect(o).to be_empty
    end

    it 'does not output when called with only one matching argument out of many' do
      command1_stub.with_args('input').outputs('arbitrary string', to: :stdout)
      o, e, _s = subject
      expect(e).to be_empty
      expect(o).to be_empty
    end
  end
end

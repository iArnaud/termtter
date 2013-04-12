require File.expand_path(File.dirname(__FILE__)) + '/../spec_helper'

module Termtter
  describe 'Command#initialize' do
    it 'requires the name element in the argument hash' do
      lambda { Command.new(:nama => :a) }.should raise_error(ArgumentError)
      lambda { Command.new(:name => :a) }.should_not raise_error(ArgumentError)
    end

    it 'does not destroy the argument hash' do
      hash = {
        :name => 'a',
        :exec => 3
      }
      Command.new hash

      hash.should eql(hash)
      hash[:name].should == 'a'
      hash[:exec].should == 3
      hash[:exec_proc].should be_nil
    end
  end

  describe Command do
    before do
      params =  {
        :name            => 'update',
        :aliases         => ['u', 'up'],
        :author          => 'ujihisa',
        :exec_proc       => lambda {|arg| arg },
        :completion_proc => lambda {|command, arg| %w[complete1 complete2] },
        :help            => ['update,u TEXT', 'test command']
      }
      @command = Command.new(params)
    end

    describe '#pattern' do
      it 'returns command regex' do
        @command.pattern.
          should == /^\s*((update|u|up)|(update|u|up)(?:\s+|\b)(.*?))\s*$/
      end
    end

    it 'is given name as String or Symbol' do
      Command.new(:name => 'foo').name.should == :foo
      Command.new(:name => :foo).name.should == :foo
    end

    it 'returns name' do
      @command.name.should == :update
    end

    it 'returns aliases' do
      @command.aliases.should == [:u, :up]
    end

    it 'returns author' do
      @command.author.should == 'ujihisa'
    end

    it 'returns commands' do
      @command.commands.should == [:update, :u, :up]
    end

    it 'returns help' do
      @command.help.should == ['update,u TEXT', 'test command']
    end

    it 'returns candidates for completion' do
      # complement
      [
        ['update  ', ['complete1', 'complete2']],
        [' update  ', ['complete1', 'complete2']],
        ['update a',  ['complete1', 'complete2']],
        ['u foo',     ['complete1', 'complete2']],
      ].each do |input, comp|
        @command.complement(input).should == comp
      end
    end

    it 'returns empty array as candidates when competition_proc is nil'do
      command = Command.new(:name => :foo)
      command.complement('foo bar').should == []
    end

    it 'returns command_info when call method "match?"' do
      [
        ['update',       true],
        ['up',           true],
        ['u',            true],
        ['update ',      true],
        [' update ',     true],
        ['update foo',   true],
        [' update foo',  true],
        [' update foo ', true],
        ['u foo',        true],
        ['up foo',       true],
        ['upd foo',      false],
        ['upd foo',      false],
      ].each do |input, result|
        @command.match?(input).should == result
      end
    end

    it 'calls exec_proc when call method "call"' do
      @command.call('foo', 'test', 'foo test').should == 'test'
      @command.call('foo', ' test', 'foo  test').should == ' test'
      @command.call('foo', ' test ', 'foo  test ').should == ' test '
      @command.call('foo', 'test test', 'foo test test').should == 'test test'
    end

    it 'raises ArgumentError at call' do
      lambda { @command.call('foo', nil, 'foo') }.
        should_not raise_error(ArgumentError)
      lambda { @command.call('foo', 'foo', 'foo') }.
        should_not raise_error(ArgumentError)
      lambda { @command.call('foo', false, 'foo') }.
        should raise_error(ArgumentError)
      lambda { @command.call('foo', Array.new, 'foo') }.
        should raise_error(ArgumentError)
    end

    describe '#alias=' do
      it 'wraps aliases=' do
        a = :ujihisa
        @command.should_receive(:aliases=).with([a])
        @command.alias = a
      end
    end

    describe '.split_command_line' do
      before do
        @command = Command.new(:name => 'test')
      end

      it 'splits from a command line string to the command name and the arg' do
        @command.split_command_line('test foo bar').
          should == ['test', 'foo bar']
        @command.split_command_line('test   foo bar').
          should == ['test', 'foo bar']
        @command.split_command_line('test   foo  bar').
          should == ['test', 'foo  bar']
        @command.split_command_line(' test   foo  bar').
          should == ['test', 'foo  bar']
        @command.split_command_line(' test   foo  bar ').
          should == ['test', 'foo  bar']
        @command.split_command_line('test ').
          should == ['test', '']
      end
    end

    describe 'spec for split_command_line with sub command' do
      before do
        @command = Command.new(:name => 'foo bar', :alias => 'f')
      end

      describe '#pattern' do
        it 'returns command regex' do
          @command.pattern.
            should == /^\s*((foo\s+bar|f)|(foo\s+bar|f)(?:\s+|\b)(.*?))\s*$/
        end
      end

      it 'splits from a command line string to the command name and the arg' do
        @command.split_command_line('foo bar args').
          should == ['foo bar', 'args']
        @command.split_command_line('foo  bar args').
          should == ['foo  bar', 'args']
        @command.split_command_line(' foo  bar  args ').
          should == ['foo  bar', 'args']
        @command.split_command_line(' foo  foo  args ').
          should == []
        @command.split_command_line('f args').
          should == ['f', 'args']
      end
    end
  end
end

#! /usr/bin/ruby

require_relative 'lib/qc/connection'

if ARGV[0] == '-u'
  raise 'username(-u username) is missing' if ARGV.length < 2
  username = ARGV[1]
  ARGV.shift
  ARGV.shift
end

if ARGV[0] == '-p'
  raise 'password(-p password) is missing' if ARGV.length < 4
  password = ARGV[1]
  ARGV.shift
  ARGV.shift
end

qc = Connection.new(username, password, 'config.yaml')
qc.connect

begin
  if ARGV.length == 0
    qc.my_defects

  elsif ARGV.length == 1
    qc.defect ARGV[0]

  elsif ARGV.length == 2
    command = ARGV[0]
    arg = ARGV[1]
    qc.open2 arg if command == 'open'
    qc.fix arg if command == 'fix'
    qc.close arg if command == 'close'
    qc.defects({'BG_STATUS' => 'New'}, :default_renderer) { |bug| bug.Summary.include? arg } if command == 'list'

  elsif ARGV.length == 3
    command = ARGV[0]
    qc.deploy ARGV[1], ARGV[2] if command == 'deploy'
    qc.comment ARGV[1], ARGV[2] if command == 'comment'
  end

ensure
  qc.disconnect
end

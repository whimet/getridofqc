#! /usr/bin/ruby
require_relative 'lib/qc/connection'

if ARGV[0] == 'help'
  puts 'qc [-u <username>] [-p <password>] <command> [<args>]'
  puts "\nSupported commands are:"
  puts '  <defect_id> - get details of specified defect'
  puts ' list <filter> - list new/open defects filtered by specified subject keyword will be used do filtering'
  puts ' open <defect_id> - change the status to Open'
  puts ' fix <defect_id> - change the status to For Fix'
  puts ' deploy <defect_id> <build_number> - change the status to For Deployment with specified build number'
  puts ' close <defect_id> - change the status to Closed'
  puts ' comment <defect_id> <comment> - add a new comment to specified defect'
  puts ' reject <defect_id> <comment> - reject a defect and assign it back to the person who raised the defect'
  puts ' '
  exit 0
end

if ARGV[0] == '-u'
  raise 'username(-u username) is missing' if ARGV.length < 2
  username = ARGV[1]
  ARGV.shift
  ARGV.shift
end

if ARGV[0] == '-p'
  raise 'password(-p password) is missing' if ARGV.length < 2
  password = ARGV[1]
  ARGV.shift
  ARGV.shift
end

def list(qc, keyword)
  qc.defects({'BG_USER_06' => app, 'BG_STATUS' => 'New or Open'}, :default_renderer) {
      |bug| bug.Summary.include? keyword
  }
end

qc = Connection.new(username, password, 'config.yaml')
qc.connect

begin
  if ARGV.length == 0
    qc.my_defects

  elsif ARGV.length == 1
    if ARGV[0] == 'list'
      list(qc, ' ')
    else
      qc.defect ARGV[0]
    end

  elsif ARGV.length == 2
    command = ARGV[0]
    arg = ARGV[1]
    qc.open2 arg if command == 'open'
    qc.fix arg if command == 'fix'
    qc.close arg if command == 'close'
    list(qc, arg) if command == 'list'

  elsif ARGV.length == 3
    command = ARGV[0]
    if command == 'deploy'
      comment = ARGV[2]
      comment = "Fixed in build #{ARGV[2]}." if (/\d+\.\d+\.\d+\.\d+/ =~ ARGV[2]) == 0
      qc.deploy ARGV[1], comment
    end

    qc.reject ARGV[1], ARGV[2] if command == 'reject'
    qc.comment ARGV[1], ARGV[2] if command == 'comment'
  end

ensure
  qc.disconnect
end

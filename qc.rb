#! /usr/bin/ruby

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

qc = Connection.new(username, password, 'config2.yaml')
qc.connect

if ARGV.length == 0
  qc.my_defects

elsif ARGV.length == 1
  id = ARGV[0]
  qc.defect id

elsif ARGV.length == 2
  command = ARGV[0]
  id = ARGV[1]
  qc.open2 id if command == 'open'
  qc.fix id if command == 'fix'
  qc.deploy id if command == 'deploy'

end

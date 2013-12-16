require 'win32ole'
require 'yaml'
require_relative 'comments'

module Defect
  class Status
    def initialize name, order
      @name = name
      @order = order
    end

    def name
      @name
    end

    def order
      @order
    end

    def after(another)
      @order > another.order
    end

    def next
      @order + 1 == ALL_STATUS.length ? nil : ALL_STATUS[@order + 1]
    end
  end

  NEW = Status.new('New', 0)
  OPEN = Status.new('Open', 1)
  FOR_FIX = Status.new('For Fix', 2)
  FOR_DEPLOY = Status.new('For Deployment', 3)
  FOR_RETEST = Status.new('For Retest', 4)
  CLOSED = Status.new('Closed', 5)
  ALL_STATUS = [NEW, OPEN, FOR_FIX, FOR_DEPLOY, FOR_RETEST, CLOSED]

  def convert(string)
    ALL_STATUS.select { |x| x.name == string }.first
  end

  def step_forward_to(bug, to_status)
    raise "invalid status: #{bug.Status}" if convert(bug.Status).after to_status

    until bug.Status == to_status.name do
      bug.Status = convert(bug.Status).next.name
      bug.Post
    end
  end
end

class Connection
  include Defect

  def initialize username, password, yaml_file
    connections = YAML.load(open(yaml_file))
    @server = connections['server']
    @username = username || connections['username']
    @password = password || connections['password']
    @domain = connections['domain']
    @project = connections['project']
  end

  def connect
    @qc = WIN32OLE.new('TDApiOle80.TDConnection')
    puts "connecting #{@project}@#{@domain} on #{@server} as #{@username}..."
    @qc.InitConnectionEx(@server)
    @qc.Login(@username, @password)
    @qc.Connect(@domain, @project)
  end

  def disconnect
    @qc.Logout
  end

  def logged_in?
    @qc.LoggedIn && @qc.ProjectName.eql?(@project)
  end

  def update_defect(id)
    bug_factory = @qc.BugFactory
    filter = bug_factory.Filter
    filter['BG_BUG_ID'] = id
    list = filter.NewList
    list.each { |bug|
      begin
        yield bug
        bug.Post
        puts "#{bug.ID}: #{bug.Status}, assigned to #{bug.AssignedTo}"
      rescue Exception => e
        bug.Undo
        puts e.message
        puts e.backtrace.inspect
      end
    }
  end

  def open2(id)
    update_defect(id) { |bug|
      if convert(bug.Status).after NEW
        puts "can't open defect #{id} with status #{bug.Status}"
        return
      end

      bug.Status = 'Open'
      bug.AssignedTo = @username
      add_comment(bug, "#{@username} is working on this issue.")
    }
  end

  def add_comment(bug, comment)
    bug['BG_DEV_COMMENTS'] = Comments.new(bug['BG_DEV_COMMENTS']).add(comment, @username).to_s
  end

  def fix(id)
    update_defect(id) { |bug|
      if convert(bug.Status).after OPEN
        puts "can't fix defect #{id} with status #{bug.Status}"
        return
      end

      bug.Status = 'For Fix'
    }
  end

  def reject(id, comment)
    update_defect(id) { |bug|
      bug.AssignedTo = bug.DetectedBy
      add_comment(bug, comment)
    }
  end

  def deploy(id, comment)
    update_defect(id) { |bug|
      if convert(bug.Status).after FOR_FIX
        puts "can't deploy defect #{id} with status #{bug.Status}"
        return
      end

      if bug.Status == 'New'
        bug.Status = 'Open'
        bug.Post
      end

      if bug.Status == 'Open'
        bug.Status = 'For Fix'
        bug.Post
      end

      bug.Status = 'For Deployment'
      bug.AssignedTo = bug.DetectedBy
      add_comment(bug, comment)
    }
  end

  def comment(id, comment)
    update_defect(id) { |bug|
      add_comment(bug, comment)
    }
  end

  def close(id)
    update_defect(id) { |bug|
      if convert(bug.Status).after FOR_RETEST
        puts "can't close defect #{id} with status #{bug.Status}"
        return
      end

      if bug.Status != FOR_RETEST.name
        step_forward_to(bug, FOR_RETEST)
      end

      bug.Status = 'Closed'
    }
  end

  def defect(ids)
    defects({'BG_BUG_ID' => ids.gsub(',', ' or ')}, :renderer_with_desc)
  end

  def my_defects
    defects({'BG_RESPONSIBLE' => @username, 'BG_STATUS' => 'not Closed'}, :default_renderer)
  end

  def defects(criteria, renderer)
    bug_factory = @qc.BugFactory
    filter = bug_factory.Filter
    criteria.each { |key, value|
      filter[key] = value
    }
    list = filter.NewList
    count = 0
    list.each { |bug|
      if !block_given? || (yield bug)
        puts self.send(renderer, bug)
        count = count + 1
      end
    }
    puts "Total: #{count}" if count > 5
  end

  def default_renderer(bug)
    "#{bug.ID}(#{bug.Priority.split(' ').last()}, <#{bug.DetectedBy}, >#{bug.AssignedTo}): #{bug.Status} - #{bug.Summary}"
  end

  def renderer_with_desc(bug)
    "#{default_renderer(bug)}\n\n#{html_to_text(bug['BG_DESCRIPTION'])}\n\n#{html_to_text(bug['BG_DEV_COMMENTS'])}\n"
  end

  def html_to_text(html)
    html ? html.gsub(/<br>/, "\n").gsub(/<[^<>]+>/, '') : ''
  end
end

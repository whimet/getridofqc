require 'win32ole'

module Status
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
  end

  NEW = Status.new('New', 1)
  OPEN = Status.new('Open', 2)
  FOR_FIX = Status.new('For Fix', 3)
  FOR_DEPLOY = Status.new('For Deployment', 4)
  FOR_RETEST = Status.new('For Retest', 5)
  CLOSED = Status.new('Closed', 6)
  ALL_STATUS = [NEW, OPEN, FOR_FIX, FOR_DEPLOY, FOR_RETEST, CLOSED]

  def convert(string)
    ALL_STATUS.select { |x| x.name == string }.first
  end
end

class Connection
  include Status

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
      yield bug
      bug.Post
      puts "#{bug.ID}: #{bug.Status}, assigned to #{bug.AssignedTo}"
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
      bug.Post
    }
  end

  def fix(id)
    update_defect(id) { |bug|
      if convert(bug.Status).after OPEN
        puts "can't fix defect #{id} with status #{bug.Status}"
        return
      end

      bug.Status = 'For Fix'
      bug.Post
    }
  end

  def deploy(id)
    update_defect(id) { |bug|
      if convert(bug.Status).after FOR_FIX
        puts "can't deploy defect #{id} with status #{bug.Status}"
        return
      end

      if bug.Status == 'Open'
        bug.Status = 'For Fix'
        bug.Post
      end

      bug.Status = 'For Deployment'
      bug.AssignedTo = bug.DetectedBy
      bug.Post
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
    list.each { |bug|
      puts self.send(renderer, bug)
    }
  end

  def default_renderer(bug)
    "#{bug.ID}(<#{bug.DetectedBy}, >#{bug.AssignedTo}): #{bug.Status} - #{bug.Summary}"
  end

  def renderer_with_desc(bug)
    "#{default_renderer(bug)}\n\n#{bug['BG_DESCRIPTION']}\n"
  end
end
class Comments

  PATTERN = Regexp.new(%r{<html><body>(.+)</body></html>}m)
  DELIM = '<font color="#000080"><b>________________________________________ </b></font><br>'

  def initialize(html, time_provider = Proc.new { Time.new })
    if html && html.length > 0
      raise 'pattern not matched' if !(html =~ PATTERN)
      content = PATTERN.match(html)[1]

      @comments = content.split(DELIM)
    else
      @comments = []
    end
    @time_provider = time_provider
  end

  def last
    @comments.last
  end

  def add(comment, user)
    @comments << "<font color=\"#000080\"><b>#{display_name(user)} - #{formatted_time}: </b></font><br>#{comment}<br><font color=\"#888888\">#{user}  Ph:  Email:#{email(user)}</font><br>"
    self
  end

  def display_name(user)
    arr = user.split('_')
    "#{arr[0].capitalize} #{arr[1].capitalize}"
  end

  def email(user)
    "#{user.gsub('_', '.')}@team.telstra.com"
  end

  def formatted_time
    @time_provider.call.strftime('%-d/%m/%Y %l:%M:%S %p').gsub('  ', ' ')
  end

  def to_s
    "<html><body>#{@comments.join(DELIM)}</body></html>"
  end
end
require_relative '../lib/qc/comments'

LAST = "<font color=\"#000080\"><b>San Zhang - 5/17/2013 7:17:19 PM: </b></font><br><br>Fixed, please refer to build no.11<br><font color=\"#888888\">san_zhang  Ph:  Email:san.zhang@team.telstra.com</font><br>"
COMMENTS = "<html><body>\n<font color=\"#000080\"><b>San Zhang - 5/17/2013 2:49:54 PM: </b></font><br><br>San is working on this issue.<br><font color=\"#888888\">san_zhang  Ph:  Email:san.zhang@team.telstra.com</font><br>\n#{Comments::DELIM}#{LAST}</body></html>"

NEW = "<font color=\"#000080\"><b>Si Li - 18/05/2013 5:07:00 PM: </b></font><br>my cool comment!<br><font color=\"#888888\">si_li  Ph:  Email:si.li@team.telstra.com</font><br>"
COMMENTS_WITH_NEW = "<html><body>\n<font color=\"#000080\"><b>San Zhang - 5/17/2013 2:49:54 PM: </b></font><br><br>San is working on this issue.<br><font color=\"#888888\">san_zhang  Ph:  Email:san.zhang@team.telstra.com</font><br>\n#{Comments::DELIM}#{LAST}#{Comments::DELIM}#{NEW}</body></html>"

describe Comments, "#initialize" do
  it "empty comments" do
    comments = Comments.new ''
    comments.last.should be_nil
  end

  it "existing comments" do
    comments = Comments.new COMMENTS
    comments.last.should eq(LAST)
  end
end

describe Comments, "#add" do
  it "first comment" do
    comments = Comments.new '', Proc.new { Time.new(2013, 5, 18, 17, 7, 0) }
    comments.add 'my cool comment!', 'si_li'
    comments.to_s.should eq("<html><body>#{NEW}</body></html>")
  end

  it "non-first comment" do
    comments = Comments.new COMMENTS, Proc.new { Time.new(2013, 5, 18, 17, 7, 0) }
    comments.add 'my cool comment!', 'si_li'
    comments.last.should eq(NEW)
    comments.to_s.should eq(COMMENTS_WITH_NEW)
  end

end
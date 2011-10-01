module RunsHelper
  def formatted_backtrace(test_case)
    @in_system_backtrace = false # start from scratch
    render :partial => "backtrace", :locals => {:test_case => test_case}
  end
  
  def show_backtrace_divider?(line)
    if interesting = interesting_backtrace?(line)
      @in_system_backtrace = false
      # if it's an interesting line, no divider
    else
      was_interesting = !@in_system_backtrace
      @in_system_backtrace = true
      # if we were in interesting territory and now aren't, show a divider
      # which signifies hidden system content
      was_interesting
    end
  end
  
  def interesting_backtrace?(line)
    line =~ /koala/
  end
end
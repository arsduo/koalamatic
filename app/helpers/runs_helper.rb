module RunsHelper
  def formatted_backtrace(test_case)
    render :partial => "backtrace", :locals => {:test_case => test_case}
  end
  
  def show_backtrace_divider?(line)
    if interesting = interesting_backtrace?(line)
      @_in_system = false
      # if it's an interesting line, no divider
    else
      was_interesting = !@_in_system
      @_in_system = true
      # if we were in interesting territory and now aren't, show a divider
      # which signifies hidden system content
      was_interesting
    end
  end
  
  def interesting_backtrace?(line)
    line =~ /koala/
  end
end
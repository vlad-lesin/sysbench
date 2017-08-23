require("oltp_common")

function prepare_statements()
   sysbench.opt.range_selects = 1
   prepare_simple_ranges()
end

function event()
   execute_simple_ranges()
end

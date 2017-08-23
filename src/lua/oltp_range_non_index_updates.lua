require("oltp_common")

function prepare_statements()
   prepare_range_non_index_updates()
end

function event()
   execute_range_non_index_updates()
end

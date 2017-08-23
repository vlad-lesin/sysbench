require("oltp_common")

function prepare_statements()
   prepare_delete_only()
end

function event()
   execute_delete_only()
end

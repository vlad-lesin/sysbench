local ffi = require("ffi")

ffi.cdef[[
unsigned int sleep(unsigned int seconds);
]]

require("oltp_common")

local function isempty(s)
  return s == nil or s == ''
end

function prepare_statements()

  local number_of_service_threads = sysbench.opt.fops_threads_num;

  if not isempty(sysbench.opt.toku_hotbackup_dir) then
    number_of_service_threads = number_of_service_threads + 1
  end

  if (sysbench.opt.threads < number_of_service_threads + 1) then
    error(string.format("For this test the number " ..
      "if threads must be greater or equal to %d",
      number_of_service_threads + 1))
  end

  if (sysbench.opt.tables < 2) then
    error("For this test the number " ..
          "of tables must be greater or equal to 2")
  end

  if sysbench.tid < number_of_service_threads then
    return
  end

  if not sysbench.opt.skip_trx then
    prepare_begin()
    prepare_commit()
  end

    prepare_point_selects()

  if sysbench.opt.range_selects then
    prepare_simple_ranges()
    prepare_sum_ranges()
    prepare_order_ranges()
    prepare_distinct_ranges()
  end

  prepare_index_updates()
  prepare_non_index_updates()
  prepare_delete_inserts()

end

function read_write()
  if not sysbench.opt.skip_trx then
    begin()
  end

  execute_point_selects()

  if sysbench.opt.range_selects then
     execute_simple_ranges()
     execute_sum_ranges()
     execute_order_ranges()
     execute_distinct_ranges()
  end

  execute_index_updates()
  execute_non_index_updates()
  execute_delete_inserts()

  if not sysbench.opt.skip_trx then
     commit()
  end
end

function event()
  if sysbench.tid < sysbench.opt.fops_threads_num then
    ffi.C.sleep(sysbench.rand.uniform(1, sysbench.opt.fops_max_period))
    execute_fops()
  elseif sysbench.tid == sysbench.opt.fops_threads_num and
         not isempty(sysbench.opt.toku_hotbackup_dir) then
    ffi.C.sleep(
      sysbench.rand.uniform(1, sysbench.opt.toku_hotbackup_max_period))
    execute_hotbackup()
  else
    read_write()
  end
end


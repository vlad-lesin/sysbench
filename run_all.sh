#!/bin/bash
set -x

DATA=r.8k.comp
DEFAULT_FILE=./my.r.8k.comp.cnf
ENGINE=TokuDB
MYSQL_SOCKET=/tmp/mysql.r.8k.comp.sock

TIME_TO_RUN=3600
WARMUP_TIME=120
TABLE_SIZE=2000000000
NUM_TABLES=1
#TABLE_SIZE=25000000
#NUM_TABLES=20

DST=/data/flash/vlesin/$DATA
SRC=/mnt/storage/vlesin/initial/$DATA
SYSMON=/home/vlesin/r/sysmon
IOSTAT=$SYSMON/iostat.sh
VMSTAT=$SYSMON/vmstat.sh
DISKSTATS=$SYSMON/diskstats.sh
LOGS=$SYSMON/$DATA
SYSBENCH_DIR=/home/vlesin/r/sysbench
PSC_DIR=/home/vlesin/r/57-psc

pushd .

#rm -rf $DST
#time cp -R $SRC $DST

cd $PSC_DIR
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1 bin/mysqld  --defaults-file=$DEFAULT_FILE --gdb 2>&1 &
sleep 10

cd $SYSBENCH_DIR
LD_LIBRARY_PATH=$PSC_DIR/lib src/sysbench ./src/lua/select_random_points_pk.lua --mysql-db=test --mysql-user=root --mysql-password="" --mysql-socket=$MYSQL_SOCKET --mysql-storage-engine=$ENGINE --threads=40 --tables=$NUM_TABLES --auto_inc=off --table_size=$TABLE_SIZE --report-interval=1 --random_points=10 --time=3600 warmup &
sleep $WARMUP_TIME
killall sysbench
cd $PSC_DIR
out1=$(bin/mysql -B test -uroot --socket=$MYSQL_SOCKET --disable-column-names  -e "select concat('KILL ',id,';') from information_schema.processlist where info like \"%sbtest%\" and time >= $WARMUP_TIME;");
bin/mysql -B test -uroot --socket=$MYSQL_SOCKET --disable-column-names  -e "$out1"
sleep 5;
bin/mysql -uroot --socket=$MYSQL_SOCKET test -e 'show processlist'

#point reads
cd $PSC_DIR
bin/mysql -uroot --socket=$MYSQL_SOCKET test -e 'purge binary logs before now()'
THELOG=$LOGS/point_reads
mkdir -p $THELOG
cd $THELOG
$IOSTAT &
$VMSTAT &
$DISKSTATS &
cd $SYSBENCH_DIR
(date; LD_LIBRARY_PATH=$PSC_DIR/lib src/sysbench ./src/lua/select_random_points_pk.lua --mysql-db=test --mysql-user=root --mysql-password="" --mysql-socket=$MYSQL_SOCKET --mysql-storage-engine=$ENGINE --threads=40 --tables=$NUM_TABLES --auto_inc=off --table_size=$TABLE_SIZE --report-interval=1 --random_points=10 --time=$TIME_TO_RUN run; date) | tee $THELOG/sysbench.log
#(date; LD_LIBRARY_PATH=$PSC_DIR/lib src/sysbench ./src/lua/oltp_point_select.lua --mysql-db=test --mysql-user=root --mysql-password="" --mysql-socket=$MYSQL_SOCKET --mysql-storage-engine=$ENGINE --threads=40 --tables=$NUM_TABLES --auto_inc=off --table_size=$TABLE_SIZE --report-interval=1 --time=$TIME_TO_RUN run; date) | tee $THELOG/sysbench.log

killall iostat
killall vmstat
killall diskstats.sh

#range reads
cd $PSC_DIR
bin/mysql -uroot --socket=$MYSQL_SOCKET test -e 'purge binary logs before now()'
THELOG=$LOGS/range_reads
mkdir -p $THELOG
cd $THELOG
$IOSTAT &
$VMSTAT &
$DISKSTATS &
cd $SYSBENCH_DIR
(date; LD_LIBRARY_PATH=$PSC_DIR/lib src/sysbench ./src/lua/select_random_ranges_pk.lua --mysql-db=test --mysql-user=root --mysql-password="" --mysql-socket=$MYSQL_SOCKET --mysql-storage-engine=$ENGINE --threads=40 --tables=$NUM_TABLES --auto_inc=off --table_size=$TABLE_SIZE --report-interval=1 --time=$TIME_TO_RUN --number_of_ranges=10 --delta=300 run; date) | tee $THELOG/sysbench.log
#(date; LD_LIBRARY_PATH=$PSC_DIR/lib src/sysbench ./src/lua/oltp_simple_ranges_select.lua --mysql-db=test --mysql-user=root --mysql-password="" --mysql-socket=$MYSQL_SOCKET --mysql-storage-engine=$ENGINE --threads=40 --tables=$NUM_TABLES --auto_inc=off --table_size=$TABLE_SIZE --report-interval=1 --time=$TIME_TO_RUN --range_size=300 run; date) | tee $THELOG/sysbench.log

killall iostat
killall vmstat
killall diskstats.sh

#point updates
cd $PSC_DIR
bin/mysql -uroot --socket=$MYSQL_SOCKET test -e 'purge binary logs before now()'
THELOG=$LOGS/point_updates
mkdir -p $THELOG
cd $THELOG
du -hs $DST/data > ./db.size.before
$IOSTAT &
$VMSTAT &
$DISKSTATS &
cd $SYSBENCH_DIR
(date; LD_LIBRARY_PATH=$PSC_DIR/lib src/sysbench ./src/lua/oltp_update_non_index.lua --mysql-db=test --mysql-user=root --mysql-password="" --mysql-socket=$MYSQL_SOCKET --mysql-storage-engine=$ENGINE --threads=40 --tables=$NUM_TABLES --auto_inc=off --table_size=$TABLE_SIZE --report-interval=1 --time=$TIME_TO_RUN run; date) | tee $THELOG/sysbench.log
killall iostat
killall vmstat
killall diskstats.sh
cd $THELOG
du -hs $DST/data > ./db.size.after

#range updates
cd $PSC_DIR
bin/mysql -uroot --socket=$MYSQL_SOCKET test -e 'purge binary logs before now()'
THELOG=$LOGS/range_updates
mkdir -p $THELOG
cd $THELOG
du -hs $DST/data > ./db.size.before
$IOSTAT &
$VMSTAT &
$DISKSTATS &
cd $SYSBENCH_DIR
(date; LD_LIBRARY_PATH=$PSC_DIR/lib src/sysbench ./src/lua/oltp_range_non_index_updates.lua  --mysql-db=test --mysql-user=root --mysql-password="" --mysql-socket=$MYSQL_SOCKET --mysql-storage-engine=$ENGINE --threads=40 --tables=$NUM_TABLES --auto_inc=off --table_size=$TABLE_SIZE --report-interval=1 --time=$TIME_TO_RUN --range_size=100 run; date) | tee $THELOG/sysbench.log
killall iostat
killall vmstat
killall diskstats.sh
cd $THELOG
du -hs $DST/data > ./db.size.after

killall mysqld

popd

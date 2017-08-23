#!/bin/bash
set -x

GEN_DIR=/mnt/m500/vlesin
NUM_ROWS=500000000
#NUM_ROWS=10000
SYSBENCH_DIR=/home/vlesin/r/sysbench
PSC_DIR=/home/vlesin/r/57-psc

DATA_NAME=t
DATA_DIR=$GEN_DIR/$DATA_NAME
DEFAULT_FILE=$PSC_DIR/my.t.comp.cnf
ENGINE=TokuDB
SOCKET=/tmp/mysql.t.comp.sock
PID_FILE=/tmp/mysql.t.comp.pid

pushd .

mkdir -p $DATA_DIR/bl $DATA_DIR/data $DATA_DIR/log $DATA_DIR/tmp
cd $PSC_DIR
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1 bin/mysqld  --defaults-file=$DEFAULT_FILE --gdb --initialize-insecure
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1 bin/mysqld  --defaults-file=$DEFAULT_FILE --gdb --pid-file=$PID_FILE &
sleep 10

bin/mysql -uroot --socket=$SOCKET -e "create database test"

cd $SYSBENCH_DIR
LD_LIBRARY_PATH=$PSC_DIR/lib src/sysbench ./src/lua/oltp_common.lua --mysql-db=test --mysql-user=root --mysql-password="" --mysql-socket=$SOCKET --mysql-storage-engine=$ENGINE --threads=48 --tables=1 --auto_inc=off --table_size=$NUM_ROWS prepare

kill `cat $PID_FILE`
sleep 10

DATA_NAME=r.8k
DATA_DIR=$GEN_DIR/$DATA_NAME
DEFAULT_FILE=$PSC_DIR/my.r.8k.comp.cnf
ENGINE=RocksDB
SOCKET=/tmp/mysql.r.comp.sock
PID_FILE=/tmp/mysql.r.comp.pid

mkdir -p $DATA_DIR/bl $DATA_DIR/data $DATA_DIR/log $DATA_DIR/tmp $DATA_DIR/wal
cd $PSC_DIR
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1 bin/mysqld  --defaults-file=$DEFAULT_FILE --gdb --initialize-insecure
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1 bin/mysqld  --defaults-file=$DEFAULT_FILE --gdb --pid-file=$PID_FILE &
sleep 10

bin/mysql -uroot --socket=$SOCKET -e "create database test"

cd $SYSBENCH_DIR
LD_LIBRARY_PATH=$PSC_DIR/lib src/sysbench ./src/lua/oltp_common.lua --mysql-db=test --mysql-user=root --mysql-password="" --mysql-socket=$SOCKET --mysql-storage-engine=$ENGINE --threads=48 --tables=1 --auto_inc=off --table_size=$NUM_ROWS prepare

kill `cat $PID_FILE`
sleep 10

popd

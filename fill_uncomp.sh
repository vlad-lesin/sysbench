#!/bin/bash
set -x

GEN_DIR=/data/flash/vlesin
NUM_ROWS=2000000000
NUM_TABLES=1
#NUM_ROWS=25000000
#NUM_TABLES=20
#NUM_ROWS=10000
SYSBENCH_DIR=/home/vlesin/r/sysbench
PSC_DIR=/home/vlesin/r/57-psc




DATA_NAME=t.1M.128.comp
DATA_DIR=$GEN_DIR/$DATA_NAME
DEFAULT_FILE=$PSC_DIR/my.t.1M.128.comp.cnf
ENGINE=TokuDB
SOCKET=/tmp/mysql.t.1M.128.comp.sock
PID_FILE=/tmp/mysql.t.1M.128.comp.pid

pushd .

mkdir -p $DATA_DIR/bl $DATA_DIR/data $DATA_DIR/log $DATA_DIR/tmp
cd $PSC_DIR
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1 bin/mysqld  --defaults-file=$DEFAULT_FILE --gdb --initialize-insecure
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1 bin/mysqld  --defaults-file=$DEFAULT_FILE --gdb --pid-file=$PID_FILE &
sleep 10

bin/mysql -uroot --socket=$SOCKET -e "create database test"

cd $SYSBENCH_DIR
LD_LIBRARY_PATH=$PSC_DIR/lib src/sysbench ./src/lua/oltp_common.lua --mysql-db=test --mysql-user=root --mysql-password="" --mysql-socket=$SOCKET --mysql-storage-engine=$ENGINE --threads=48 --tables=$NUM_TABLES --auto_inc=off --table_size=$NUM_ROWS prepare

kill `cat $PID_FILE`
sleep 10

popd





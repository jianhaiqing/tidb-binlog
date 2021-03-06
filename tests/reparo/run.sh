#!/bin/sh

set -e

cd "$(dirname "$0")"

# use latest ts as initial-commit-ts, so we can skip binlog by previous test case
ms=$(date +'%s')
ts=$(($ms*1000<<18))
args="-initial-commit-ts=$ts"
down_run_sql "DROP DATABASE IF EXISTS tidb_binlog"
rm -rf /tmp/tidb_binlog_test/data.drainer

run_drainer "$args" &

run_sql "DROP DATABASE IF EXISTS \`reparo_test\`;"
run_sql "CREATE DATABASE \`reparo_test\`"
run_sql "CREATE TABLE \`reparo_test\`.\`test\`(\`id\` int, \`name\` varchar(10), \`all\` varchar(10), PRIMARY KEY(\`id\`))"

run_sql "INSERT INTO \`reparo_test\`.\`test\` VALUES(1, 'a', 'a'), (2, 'b', 'b')"
run_sql "INSERT INTO \`reparo_test\`.\`test\` VALUES(3, 'c', 'c'), (4, 'd', 'c')"
run_sql "UPDATE \`reparo_test\`.\`test\` SET \`name\` = 'bb' where \`id\` = 2"
run_sql "DELETE FROM \`reparo_test\`.\`test\` WHERE \`id\` = '1'"
run_sql "INSERT INTO \`reparo_test\`.\`test\` VALUES(5, 'e', 'e')"

sleep 5

run_reparo &

sleep 15

check_data ./sync_diff_inspector.toml 

# clean up
run_sql "DROP DATABASE IF EXISTS \`reparo_test\`"

killall drainer

# Getting started

## ツールのインストール
```
$ make install_all

# update nginx.conf
$ vi /etc/nginx/nginx.conf to change log format
...
    log_format ltsv "time:$time_local"
    "\thost:$remote_addr"
    "\tforwardedfor:$http_x_forwarded_for"
    "\treq:$request"
    "\tmethod:$request_method"
    "\turi:$request_uri"
    "\tstatus:$status"
    "\tsize:$body_bytes_sent"
    "\treferer:$http_referer"
    "\tua:$http_user_agent"
    "\treqtime:$request_time"
    "\truntime:$upstream_http_x_runtime"
    "\tapptime:$upstream_response_time"
    "\tcache:$upstream_http_x_cache"
    "\tvhost:$host";

    access_log /var/log/nginx/access.log ltsv;

# update my.conf to enable slow log and change max connections
$ vi /etc/mysql/my.cnf
...
    [mysqld]
    character-set-server=utf8mb4

    # max connections
    max_connections = 1024

    # slow query
    slow_query_log = 1
    long_query_time = 0
    slow_query_log-file = /var/log/mysql/slow.log

    [mysql]
    default-character-set=utf8mb4
    [client]
    default-character-set=utf8mb4
...

# Run benchmarker
$ benchmarker

# Check slow log
$ chmod +r /var/log/mysql/slow.log
$ make exec-percona
```

## ディレクトリセットアップ
```
$ ./setup.sh
```

## Go Profiler
[pprof](https://pkg.go.dev/net/http/pprof) を使用する

### コードを変更する
$ vi main.go
```
import _ "net/http/pprof"
...
go func() {
	log.Println(http.ListenAndServe(":6060", nil))
}()
...
```

## 実行結果を確認する

// テストを実行中にローカル端末で下記を実行する
```
$ go tool pprof -http=":8080" "http://x.x.x.x:6060/debug/pprof/profile?seconds=60"
```

// 実行後のに出力される結果ファイルを指定して確認する場合は、下記を実行する
```
$ go tool pprof -http=":8080" ~/Downloads/pprof.isuconquest.samples.cpu.002.pb.gz
```

## 調査手順
1. ベンチ実行時に下記の情報を確認する: pprof, slow log, performance info (top, dstat)

## MySQL Replication

[参考: MySQL レプリケーション遅延と不整合を体験してみよう](https://qiita.com/suzuki_sh/items/8607ec26c91e013f65f6)

```
# Master と Slave にそれぞれ異なる server-id を指定する
$ vi /etc/mysql/my.cnf
...
    [mysqld]
    server-id=1
...

# Master 側に replication ユーザを作成する
# X.X.X.X は Slave の IP
$ mysql -u root -p
...
    Create user ‘repl’@’X.X.X.X’ identified by ‘replpwd’;
    Grant replication slave on *.* to ‘repl’@’X.X.X.X’;
    GRANT ALL PRIVILEGES ON *.* TO ‘repl’@’X.X.X.X’;
...

# Master 側でリモートアクセスを許可する
$ vi /etc/mysql/mysql.conf.d/mysqld.cnf
...
    bind-address = 0.0.0.0
...

# Master を再起動する
$ sudo systemctl restart mysql

# Master の binlog の状態を確認する
$ $ mysql -u root -h 127.0.0.1 -P 3306 -e "SHOW MASTER STATUS\G"

# Slave 側で auto.cnf を削除する
$ rm /var/lib/mysql/auto.cnf

# Slave を再起動する
$ sudo systemctl restart mysql

# Slave 側で replication 設定を行う
$ mysql -u root -h 127.0.0.1 -P 23306
...
$ CHANGE MASTER TO
    MASTER_HOST=''Y.Y.Y.Y',
    MASTER_PORT=3306,
    MASTER_USER='root',
    MASTER_PASSWORD='AAAAAAAA',
    MASTER_LOG_FILE='<MasterLogFile>', # Master の binlog の状態確認で確認したもの
    MASTER_LOG_POS=<MasterLogPosition>; # Master の binlog の状態確認で確認したもの
...
$ START SLAVE;
$ SHOW SLAVE STATUS\G

# Slave の Replication を確認する
$ mysql -u root -h 127.0.0.1 -P 3306 -e "SHOW SLAVE STATUS\G" | grep Running:
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
```

## インデックスを貼る
```
ALTER TABLE `user_present_all_received_history` ADD INDEX idx_user_present_all_received_history(user_id, present_all_id);
```

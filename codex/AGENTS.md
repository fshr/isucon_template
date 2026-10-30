# AGENTS.md — ISUCON 2026 エージェント運用指示書

## 大会前の設定 — 人間が書き換える項目はここだけ

**この表がユーザーによる設定項目の唯一の一覧である。** エージェントは最初にこの節を読み、SSH 接続情報は `servers.txt` を参照すること。

| 項目 | 編集場所 | 設定する値 | 必要な時点 |
| --- | --- | --- | --- |
| GitHub リポジトリ | この節の `GITHUB_REPOSITORY_URL` | 実際のリポジトリ URL | Issue 作成・push・PR 作成前 |
| サーバー1のアドレス | `servers.txt` の `[server1] HOST` | IP アドレスまたは DNS 名 | 最初の SSH 接続前 |
| サーバー1のユーザー | `[server1] SSH_USER` | SSH ログインユーザー | 最初の SSH 接続前 |
| サーバー1の秘密鍵 | `[server1] SSH_KEY` | エージェント実行環境に存在する秘密鍵ファイルの絶対パス | 最初の SSH 接続前 |
| サーバー2・3の接続情報 | `[server2]`・`[server3]` | `HOST`・`SSH_USER`・`SSH_KEY` | スケールアウト時 |
| SSH ポート | 各 `SSH_PORT` | 22 以外の場合のみ変更 | 各サーバーへの接続前 |

**書き換える GitHub 設定（この1か所のみ）：**

```text
GITHUB_REPOSITORY_URL=https://github.com/EXAMPLE-ORG/isucon2026
```

- 実際の URL が判明するまでサンプル URL にアクセスしたり Issue/PR を作成したりしない。
- `ROLE=primary`（サーバー1）と `ROLE=standby`（サーバー2・3）は意図した初期値であり、変更不要。
- `servers.txt` に秘密鍵の中身を書かない。`.gitignore` に登録して Git 管理対象外とする。
- 以降の nginx/MySQL 設定、Makefile のコマンドやパスは運用上の想定値であり、事前にユーザーが埋める項目ではない。実環境で有効値を検証すること。
- 公式レギュレーション、ベンチマーク実行方法、アプリ固有のエンドポイントは大会当日に確認する。

---

## ミッション

あなたは ISUCON 2026 に参加するパフォーマンス改善エージェントである。**公式レギュレーションとアプリケーションの正当性を守りながら、有効な公式ベンチマークスコアを最大化する。** 推測による大規模変更より、計測に基づく改善を優先する。報告・Issue・PR の説明は原則日本語で行う。

## 最初に行うことと情報の優先順位

1. 公式レギュレーション、README、ソースコード、ベンチマーク手順、デプロイスクリプトを読む。過去の ISUCON の構成・採点方法・許可操作を 2026 年大会に当てはめない。
2. `git status`、サービス稼働状況、CPU/メモリ/ディスク、DB スキーマ、アプリ起動方法、デプロイ構成を確認し、ベースラインのコミットと設定を記録する。
3. 正式なベンチマークコマンド、合格条件、副作用を確認する。破壊的・外部影響のある操作の権限が不明なら事前確認する。
4. 公式情報が未入手なら前提を明記し、安全な読み取り調査を進める。足りない情報は質問する。

## 絶対に守る制約

- 公式仕様・レギュレーションに従う。検証の無効化、偽レスポンス、ベンチマーカーの改変、ベンチマーク固有の答えのハードコードは禁止。
- 認証、認可、セッション、永続性、順序、レスポンス互換性を維持する。
- 秘密情報、秘密鍵、実データを出力・コミットしない。
- 無断のテーブル削除、データの TRUNCATE、永続性の放棄、ホスト再起動、FW/ネットワークポリシー変更は禁止。影響の大きい操作には明示的な許可を得る。
- 変更はロールバック可能にし、設定のバックアップと移行計画を残す。同時に多数の未計測変更を入れない。
- サーバーやサービスの使用は当日の公式ルールの範囲内に限る。

## 改善ループ

1. **観測：** 有効なベースラインベンチマークを実行し、スコア、成否、スループット、遅延、エラー、資源使用量を記録する。
2. **診断：** SQL、クエリ回数、CPU、ロック、メモリアロケーション、GC、ディスク I/O、ネットワーク、nginx/upstream などを測定し、最大の制約を特定する。
3. **仮説：** 改善の仕組み、期待する指標、正当性へのリスクを明文化する。
4. **変更：** 効果の高い最小限の変更を行う。必要に応じてスキーマ・設定・デプロイも修正する。
5. **検証：** テストと公式ベンチマークを実施し、ベースラインと最高記録を比較する。エラーと整合性も確認する。
6. **採用または撤回：** 正当性を満たし、スコアまたは安定性に根拠ある改善が見られた変更のみ残す。判断理由を記録する。

## 調査項目と優先順位

- リクエスト経路、読み書き、アプリから DB へのアクセス、外部依存、共有状態を把握する。
- `EXPLAIN` / `EXPLAIN ANALYZE`（対応時）、インデックス、N+1、不要なソートや COUNT、トランザクション、接続プールを調査する。
- 実際のホットパスをプロファイルし、アルゴリズム、シリアライズ、テンプレート、正規表現、並列性を検討する。
- 各ホストの CPU、メモリ、swap、ロード、ディスク遅延、FD、ソケット、ネットワークを確認する。
- nginx アクセスログ、upstream 遅延、keepalive、圧縮、バッファ、静的ファイル配信を確認する。
- キャッシュ導入時は更新時の無効化と整合性を守る。

**改善の優先順位：** ①正当性・エラー → ②高コスト SQL・N+1・インデックス → ③アプリのホットパス → ④競合・接続プール・キャッシュ → ⑤サービス構成・nginx・OS → ⑥小規模な最適化。

## ベンチマーク記録

- 各試行の日時、コミット SHA、変更ファイル、サーバー役割、実行コマンド、設定、スコア、成否、主要メトリクス、解釈を残す。
- 条件の異なる試行を比較する場合は差異を明記する。
- 残り時間を考慮し、終了前に最終検証の時間を確保する。
- 常に最後に成功した構成とロールバック手順を保持する。
- 報告形式：`スコア | 正当性 | 前回との差分 | ボトルネック | 変更内容 | 次の対応`。
- 許可されていれば `PERFORMANCE_LOG.md` に記録する。

## 調査ツールと Makefile

`fzf`、`alp`、`pt-query-digest`、MySQLTuner、phpMyAdmin は**インストール済み**とみなす。インストールやアップグレードに時間を使わず、必要に応じて直接利用する。`make install_all` を通常手順として実行しない。実際の Makefile とパスは実行前に確認する。

| ツール・ターゲット | 用途・注意点 |
| --- | --- |
| `fzf` | 対話的な選択。自動化には再現可能な非対話コマンドを優先する |
| MySQLTuner / `make exec-mysqltuner` | MySQL 設定と統計の補助調査。`/home/ubuntu/MySQLTuner-perl/mysqltuner.pl` は実環境で確認する |
| `alp` / `make exec-alp` | nginx LTSV のエンドポイント別遅延・頻度分析。URI 正規化は実ルートに合わせる |
| phpMyAdmin | 任意の DB 調査。Web 管理画面の新規公開は許可なく行わない |
| `pt-query-digest` / `make exec-percona` | MySQL slow log のクエリ別総負荷・頻度・遅延を分析する |
| `make bench` | ベンチマーク用ラッパー。アプリ再起動やログ消去の副作用を確認する |
| `make mysql` | 設定をコピーし MySQL を再起動する。ログ消去も伴う |
| `make nginx` | nginx 設定をコピーし、構文検証後に再起動する |
| `make isucholar` | `restart.sh` を実行する。実際のサービスを確認する |
| `make stop-mysql` | MySQL 停止。通常の調査では使用しない |
| `make clear-nginx-logs` | nginx access log を空にする |
| `make clear-slow-logs` | MySQL slow log を空にする |

- `make exec-alp` の `/api/courses/.+` や `/api/announcements/.+` は例示であり、2026 年の実ルートとは限らない。
- コマンドが失敗した場合のみ、インストールパスや `--help` を確認する。
- サービス再起動・停止・設定変更・ログ消去・ベンチマーク実行は共有環境に影響するため、権限とチームの実行状況を確認する。

## nginx の想定設定と LTSV ログ

提供された nginx 設定では、アクセスログは `/var/log/nginx/access.log`、形式は `ltsv`。エラーログは `/var/log/nginx/error.log`（`warn`）。`sudo nginx -T` で実際の有効設定を検証する。

| LTSV キー | nginx 変数・意味 |
| --- | --- |
| `time` | `$time_local` |
| `host` | `$remote_addr`（HTTP Host ヘッダーではなく接続元 IP） |
| `forwardedfor` | `$http_x_forwarded_for` |
| `req` | `$request` |
| `method` | `$request_method` |
| `uri` | `$request_uri`（クエリ文字列を含む） |
| `status` | `$status` |
| `size` | `$body_bytes_sent` |
| `referer` | `$http_referer` |
| `ua` | `$http_user_agent` |
| `reqtime` | `$request_time`（nginx が測定したリクエスト全体の秒数） |
| `runtime` | `$upstream_http_x_runtime`（アプリが返すヘッダー。nginx の upstream 時間ではない） |
| `apptime` | `$upstream_response_time`（upstream 応答時間。静的配信では `-` の場合あり） |
| `cache` | `$upstream_http_x_cache`（アプリが返すヘッダー。nginx キャッシュの HIT/MISS とは限らない） |
| `vhost` | `$host` |

**`alp` の応答時間キーは必ず `reqtime` を指定する。**

```bash
sudo nginx -T 2>&1 | grep -E 'log_format ltsv|access_log'
sudo head -n 3 /var/log/nginx/access.log
alp ltsv --uri-key uri --method-key method --status-key status \
  --response-time-key reqtime \
  -m '/api/courses/.+,/api/announcements/.+' \
  < /var/log/nginx/access.log
```

- `-m` はサンプルのパターンである。実ルートに応じて ID・UUID・可変パスを正規化する。
- `uri` にはクエリ文字列が含まれる。集計の分散や機密情報の露出を避けるため、必要なら一時的な解析処理で除去・正規化する。
- `reqtime` と `apptime` を比較し、nginx 側とアプリ側の時間を切り分ける。差が大きくても原因を即断しない。
- 静的ファイルの `apptime:-` はアプリ遅延として扱わない。
- `alp` のバージョンでオプションが異なる場合は `alp ltsv --help` を確認する。

### nginx の初期構成

- `worker_processes 1`、`worker_connections 4096`、`worker_rlimit_nofile 20000`、`keepalive_timeout 120`、gzip 有効。
- nginx はポート `8000` で待ち受け、`isucholar` upstream は `127.0.0.1:7000`。
- `/login`、`/logout`、`/initialize`、`/api` はアプリへプロキシする。
- `/` は `/home/isucon/webapp/frontend/dist` を配信し、SPA の `/index.html` フォールバックを使う。
- これらは**初期状態の情報**であり、無条件に変更する推奨値ではない。CPU、同時接続、静的配信、upstream エラーを測定してから調整する。
- 設定変更前にバックアップし、`sudo nginx -t` で検証する。`/initialize` の動作を壊さない。

必要に応じた `make exec-alp` の修正例：

```makefile
exec-alp: alp ## nginx LTSV アクセスログを解析
	alp ltsv --uri-key uri --method-key method --status-key status --response-time-key reqtime -m '/api/courses/.+,/api/announcements/.+' < /var/log/nginx/access.log
```

## MySQL の想定設定

提供された MySQL 設定は以下のとおり。実行中の MySQL に反映されているかを確認する。

```ini
[mysqld]
server-id=1
character-set-server=utf8mb4
max_connections=1024
slow_query_log=1
long_query_time=0
slow_query_log-file=/var/log/mysql/slow.log
disable-log-bin
# innodb_buffer_pool_size=1G
# innodb_doublewrite=0
# innodb_flush_log_at_trx_commit=0
# innodb_flush_log_at_timeout=3
# innodb_log_group_home_dir=/dev/shm
# innodb_redo_log_capacity=128M
[mysql]
default-character-set=utf8mb4
[client]
default-character-set=utf8mb4
```

- `long_query_time=0` のため、実行されたクエリは原則 slow log の記録対象になる。**総実行時間・実行頻度・個別遅延**で優先順位を付ける。ログ記録自体の負荷にも注意する。
- `disable-log-bin` によりバイナリログは無効。レプリケーションや binlog による復旧を前提にしない。
- `#` 付きの InnoDB 設定は**無効**。耐久性を弱める設定を、公式ルールと永続性要件の検証なしに有効化しない。
- `SHOW VARIABLES LIKE 'slow_query_log';`、`'slow_query_log_file'`、`'long_query_time'`、`'log_output'`、`'max_connections'` などで実効値を確認する。

## 各ベンチマーク前のログ初期化（必須）

**毎回のベンチマーク開始前に nginx access log と MySQL slow log の両方をクリアする。** 前回の試行のログを今回の `alp` / `pt-query-digest` の集計に混ぜない。

1. 前回のスコア、分析結果を保存する。比較や障害調査に必要な生ログは試行 ID を付けて退避する。
2. ログの実パスと消去権限を確認する。ファイル自体を削除したり所有権を変えたりしない。
3. ベンチマーク直前に次を実行する。

   ```bash
   make clear-nginx-logs clear-slow-logs
   ```

4. 無関係な負荷や待ち時間を挟まずベンチマークを実行する。提供された `make bench` は nginx ログのみクリアし、アプリ再起動も行うため、**MySQL ログも必ずクリアされる順序**にする。
5. ベンチマーク後、分析結果を保存するまでログを消さない。

   ```bash
   alp ltsv --uri-key uri --method-key method --status-key status \
     --response-time-key reqtime < /var/log/nginx/access.log
   pt-query-digest /var/log/mysql/slow.log
   ```

6. 同じ試行のスコア、成否、時間帯、コミット、設定、`alp` と `pt-query-digest` の結果を対応付けて保存する。

Makefile の修正例（実際のターゲットと副作用を確認してから適用）：

```makefile
.PHONY: bench
bench: clear-nginx-logs clear-slow-logs isucholar ## ログをクリアしてベンチマークを実行
	/home/isucon/isucon_template/bench.sh
```

**注意：** 再起動・ウォームアップのログを測定から除外したい場合は、再起動とウォームアップの**後**、実ベンチマーク開始の直前に両ログをクリアする。Make の依存ターゲットの実行順序に無条件で依存しない。ベンチマーク実行中はログを消さず、他エージェントの測定とも競合させない。

## チーム開発 — Git worktree と PR を必須とする

**すべてのコード・設定・ドキュメント・Makefile 変更は、専用の feature branch と独立した Git worktree で行う。** 共有 `main` 作業ディレクトリや他人の worktree を編集しない。

1. `git status`、`git branch --show-current`、`git worktree list`、remote を確認し、他人の未コミット変更を壊さない。
2. 合意済みのベース（通常 `origin/main`）から衝突しないブランチ名で worktree を作る。

   ```bash
   git fetch origin
   git worktree add -b feat/isucon-<topic>-<unique-id> ../isucon-<topic>-<unique-id> origin/main
   cd ../isucon-<topic>-<unique-id>
   ```

3. 自分の担当変更だけを実装・検証する。nginx、MySQL、systemd、デプロイスクリプトなど共有ファイルの担当を調整する。
4. `git diff` とテスト・ベンチマーク結果を確認して feature branch にコミットする。秘密情報・ログ・ローカル専用ファイルはコミットしない。
5. feature branch を push し、**PR を作成する**。目的、変更内容、正当性、スコアの前後比較、運用影響、ロールバックを記載する。push/PR 作成ができなければ障害を報告し、作成済みと偽らない。
6. PR は人間のレビュー待ちとして残す。レビュー対応は同じ feature branch への追加コミットで行う。

### main へのマージ禁止

- **ユーザーが明確に指示しない限り、`main` または保護された統合ブランチにマージしてはならない。** 実装・ベンチマーク・push・PR 作成の依頼はマージ許可ではない。
- 自動マージ、承認回避、保護ブランチへの force-push、`main` への直接コミットは禁止。
- テスト成功、スコア改善、他エージェントの承認、時間切れ間際という事情もマージ許可にならない。
- 明示的なマージ指示があっても、対象 PR、ベース、レビュー状態、保護ルールを再確認する。

### 共有ホストの競合防止

Git worktree はファイルを分離するが、**MySQL、nginx、サービス、ログ、ベンチマークホストは分離しない**。`make bench`、設定反映、再起動、DB マイグレーション、ログ消去の前にチームと調整する。別のエージェントの測定中には実行しない。どのコミットが稼働中か記録し、復旧・引き継ぎを可能にする。

## サーバー運用 — 最初は1台、計測後にスケールアウト

- 大会開始時点で**3台使えるが、最初はサーバー1の1台だけ**をアプリ・DB・nginx の実行に使う。サーバー2・3は待機させる。
- まず1台で SQL/インデックス、N+1、アプリのホットパス、nginx、CPU/メモリなどを計測・改善し、有効な最高スコアを残す。
- スコアが低いという理由だけでサーバーを増やさない。改善余地が大きい間は単一サーバーのチューニングを優先する。
- **スケールアウトの条件：** ①残り時間内に1台での追加改善が見込みにくいこと、②DB の CPU・ロック・I/O、アプリの CPU・並列処理、nginx/ネットワークなど、拡張で解消できるボトルネックが計測で特定されていること。
- 追加前に根拠、期待効果、デメリット、サーバーの役割を文書化する。DB の競合が原因なら DB 分離、アプリ処理能力が原因ならアプリのレプリカ増設など、**原因に合わせて構成を選ぶ**。
- ネットワーク遅延、共有状態、セッション、DB 接続数、キャッシュ整合性、デプロイの複雑化を考慮する。
- **一度に追加するのは1台のみ。** サーバー2を追加して測定・正当性確認し、その結果と残るボトルネックが正当化する場合に限りサーバー3を使用する。直前の正常構成を復旧できるようにする。
- 公式ルールに別の構成指定がある場合は公式ルールを優先し、相違を報告する。

## GitHub Issue によるチューニング管理（必須）

- SQL・インデックス・アプリ・nginx・MySQL・サーバー構成など、**すべての改善案は実装前に GitHub Issue を作る**。可能な限り1つの仮説につき1 Issue とする。
- リポジトリは冒頭の `GITHUB_REPOSITORY_URL` を参照する。サンプル URL のままならリモートに Issue・push・PR を作らない。
- URL 未設定時は feature worktree 内の `docs/issue-drafts/` 等に Issue の下書きを作る。実際に Issue を作成したとは報告しない。
- URL とアクセス権が確定したら `gh issue create` または許可された GitHub 連携を利用する。
- Issue のタイトル例：`[Tuning] DB: N+1 クエリ削減による総 SQL 時間の短縮`。
- Issue には現状の証拠、ボトルネック、仮説、変更案、期待効果、正当性リスク、検証コマンド、スコア前後比較、ロールバックを記載する。
- PR では Issue 番号を参照し、必要なら `Refs #123` を使用する。明示的なマージが行われるまで自動クローズを前提とする `Closes` は避ける。
- 既存 Issue を検索して重複を防ぎ、担当者・共有ホスト・設定ファイルの競合を調整する。
- Issue 作成・PR 作成は実 URL と権限確認後に許可されるが、**`main` へのマージはユーザーの明示指示が必要**。

## サーバー接続情報 — `servers.txt`

- リポジトリルートの `servers.txt` から3台分の `HOST`、`SSH_USER`、`SSH_PORT`、`SSH_KEY` を読む。
- `SSH_KEY` は秘密鍵ファイルへの**パス**。秘密鍵本体・パスワード・トークンを書かない。
- `servers.txt` はローカル専用とし、`.gitignore` に追加する。実 IP・鍵パスを Issue/PR/ログに貼らない。
- 信頼できる方法で SSH ホスト鍵を確認し、`StrictHostKeyChecking` を無効化して接続しない。
- 最初は `server1` のみ接続・デプロイする。`server2`・`server3` は前述の条件を満たしチームで調整した場合に使用する。
- プレースホルダーが残っていたら接続前にユーザーへ入力を依頼する。

## 時間管理と終了条件

- **序盤：** 公式ルール確認、ベースライン、ボトルネック調査、優先順位付け。
- **中盤：** 効果の高い変更を小さく実装し、繰り返しベンチマークする。
- **終盤：** 危険なリファクタリングを止め、最高スコアの検証済み構成へ戻し、最終ベンチマーク・サービス稼働・永続性を確認する。
- 終了時は、①公式ルールと正当性、②起動とベンチマーク成功、③最高有効スコアの記録、④必要なデプロイ・設定変更の保存、⑤復旧手順を満たす。
- 大会当日に未確定情報（ルール、採点方法、言語、サービス、DB、許可操作、終了手順）を確認し、推測で埋めない。


##@ Basic
.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Tools
.PHONY: isntall_all
install_all: fzf mysqltuner alp phpmyadmin percona ## Install all if necessary


.PHONY: fzf
fzf: ## Install fzf if necessary
	if ! which fzf >/dev/null; then \
		git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf; \
		~/.fzf/install; \
	fi

.PHONY: mysqltuner
mysqltuner: ## Install mysqltuner if necessary
	if ! test -f ~/MySQLTuner-perl/mysqltuner.pl; then \
		git clone https://github.com/major/MySQLTuner-perl ~/MySQLTuner-perl; \
	fi

.PHONY: alp
alp: ## Install alp if necessary
	if ! which alp >/dev/null; then \
		env GOFLAGS= go install github.com/tkuchiki/alp/cli/alp@latest; \
	fi

.PHONY: phpmyadmin
phpmyadmin: ## Install phpmyadmin if necessary
	sudo add-apt-repository ppa:phpmyadmin/ppa -y
	sudo apt-get update -y
	sudo apt-get install phpmyadmin -y

.PHONY: percona
percona: ## Install percona if necessary
	sudo apt-get install percona-toolkit -y

##@ Update systemd-units
.PHONY: mysql
mysql: clear-slow-logs ## Update mysql unit
	sudo cp /home/isucon/isucon_template/my.cnf /etc/mysql/conf.d/my.cnf
	sudo systemctl restart mysql

.PHONY: isucholar
isucholar: ## Update isumo unit
	/home/isucon/isucon_template/restart.sh

.PHONY: nginx
nginx: ## Update nginx unit
	sudo cp /home/isucon/isucon_template/nginx.conf /etc/nginx/nginx.conf
	sudo nginx -t
	sudo systemctl restart nginx

##@ Exec tools
.PHONY: exec-alp
exec-alp: alp ## Execute alp
	cat /var/log/nginx/access.log | alp ltsv -m "/api/courses/.+,/api/announcements/.+"

.PHONY: exec-mysqltuner
exec-mysqltuner: ## Execute mysqltuner
	sudo perl /home/ubuntu/MySQLTuner-perl/mysqltuner.pl

.PHONY: bench
bench: clear-nginx-logs isucholar ## Execute bench
	/home/isucon/isucon_template/bench.sh

.PHONY: exec-percona
exec-percona: ## Execute pt-query-digest
	pt-query-digest /var/log/mysql/slow.log

##@ Stop
.PHONY: stop-mysql
stop-mysql: ## Stop mysql unit
	sudo systemctl stop mysql

##@ Clean
.PHONY: clear-nginx-logs
clear-nginx-logs: ## Clear nginx logs
	sudo sh -c 'echo "" > /var/log/nginx/access.log'

.PHONY: clear-slow-logs
clear-slow-logs: ## Clear mysql slow logs
	sudo sh -c 'echo "" > /var/log/mysql/slow.log'

all: orthodoxy the-free-press guilds-trade servile-state

%: common.book %.book ./%/*.md
	-mkdir -p ../books/$@
	crowbook $@.book

clean:
	-rm -r ../books
all: orthodoxy the-free-press guilds-trade servile-state utopia-usurers

%: common.book %.book ./%/*.md
	-mkdir -p ../books/$@
	../crowbook/target/release/crowbook $@.book

clean:
	-rm -r ../books
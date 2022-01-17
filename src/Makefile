all: orthodoxy the-free-press guilds-trade servile-state utopia-usurers economic-democracy

%: common.book %.book ./%/*.md
	-mkdir -p ../books/$@
	../crowbook/target/release/crowbook $@.book
	ebook-convert ../books/$@.epub ../books/$@.mobi

clean:
	-rm -r ../books
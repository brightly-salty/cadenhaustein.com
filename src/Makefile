all: acquisitive-society agrarian-justice christianity-patriotism condition-labor control-distribution economic-democracy economics-helen flight-from-city guilds-trade guildsman-history kingdom-within napoleon-notting orthodoxy outline-sanity restoration-guild saw-america servile-state social-problems st-francis the-free-press utopia-usurers

%: common.book %/__.book %/*.md
	-mkdir -p ../books/$@
	crowbook $@/__.book
	ebook-convert ../books/$@.epub ../books/$@.mobi
	
clean:
	-rm -r ../books
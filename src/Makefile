all: acquisitive-society agrarian-justice christianity-patriotism condition-labor control-distribution economic-democracy economics-helen eugenics-evils flight-from-city garrison-nonresistance guilds-crisis guilds-trade guildsman-history history-england kingdom-within man-thursday napoleon-notting orthodoxy outline-sanity restoration-guild saw-america servile-state social-problems st-francis the-free-press utopia-usurers whats-wrong

%: common.book %/__.book %/*.md
	-mkdir -p ../books/$@
	crowbook $@/__.book
	ebook-convert ../books/$@.epub ../books/$@.mobi
	
clean:
	-rm -r ../books
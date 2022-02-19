all: agrarian-justice christianity-patriotism condition-labor control-distribution economic-democracy economics-helen eugenics-evils flight-from-city guilds-trade guildsman-history napoleon-notting orthodoxy outline-sanity restoration-guild saw-america servile-state social-problems the-free-press utopia-usurers

%: common.book %/__.book %/*.md
	-mkdir -p ../books/$@
	crowbook $@/__.book
	ebook-convert ../books/$@.epub ../books/$@.mobi
	-mv ../books/$@/menu.svg ../images
	-mv ../books/$@/stylesheet.css ../styles
	-mv ../books/$@/print.css ../styles
	
clean:
	-rm -r ../books

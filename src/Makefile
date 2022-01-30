%: common.book %/__.book %/*.md
	-mkdir -p ../books/$@
	crowbook $@/__.book
	ebook-convert ../books/$@.epub ../books/$@.mobi
	-mv ../books/$@/menu.svg ../images
	-mv ../books/$@/stylesheet.css ../styles
	-mv ../books/$@/print.css ../styles
	
clean:
	-rm -r ../books

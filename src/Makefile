%: common.book %/__.book %/*.md
	-mkdir -p ../books/$@
	../crowbook/target/release/crowbook $@/__.book
	ebook-convert ../books/$@.epub ../books/$@.mobi
	-cleancss ../books/$@/stylesheet.css -o stylesheet.min.css && mv stylesheet.min.css ../books/$@/stylesheet.css
	-cleancss ../books/$@/print.css -o print.min.css && mv print.min.css ../books/$@/print.css

clean:
	-rm -r ../books

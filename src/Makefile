%: common.book %/__.book %/*.md
	-mkdir -p ../books/$@
	crowbook/target/release/crowbook ../src/$@/__.book
	ebook-convert ../books/$@.epub ../books/$@.mobi
	cleancss ../books/$@/stylesheet.css -o ../books/$@/stylesheet.min.css
	mv ../books/$@/stylesheet.min.css ../books/$@/stylesheet.css
	cleancss ../books/$@/print.css -o ../books/$@/print.min.css
	mv ../books/$@/print.min.css ../books/$@/print.css

clean:
	-rm -r ../books
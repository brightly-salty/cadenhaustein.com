all: orthodoxy the-free-press guilds-trade servile-state utopia-usurers economic-democracy

%: src/common.book src/%.book src/%/*.md
	-mkdir -p books/$@
	crowbook/target/release/crowbook src/$@.book
	ebook-convert books/$@.epub books/$@.mobi
	cleancss books/$@/stylesheet.css -o books/$@/stylesheet.min.css
	mv books/$@/stylesheet.min.css books/$@/stylesheet.css
	cleancss books/$@/print.css -o books/$@/print.min.css
	mv books/$@/print.min.css books/$@/print.css

clean:
	-rm -r ../books
all: acquisitive-society agrarian-justice christianity-patriotism condition-labor control-distribution economic-democracy economics-helen eugenics-evils flight-from-city garrison-nonresistance guilds-crisis guilds-trade guildsman-history kingdom-within man-thursday napoleon-notting orthodoxy outline-sanity restoration-guild saw-america servile-state social-problems st-francis the-free-press utopia-usurers whats-wrong

%: %.tex
	-mkdir -p ../books/$@
	latexindent -silent -overwrite $@.tex
	pandoc -f latex -t pdf --wrap=auto --toc -s --ascii --reference-location=block --pdf-engine=xelatex $@.tex -o ../books/$@.pdf --quiet
	pandoc -f latex -t html --wrap=auto --toc -s --ascii --reference-location=block --template=../templates/pandoc.html $@.tex -o ../books/$@/index.html --quiet
	-tidy -quiet -modify -omit ../books/$@/index.html
	pandoc -f latex -t epub3 --wrap=auto --toc -s --ascii --reference-location=block --template=../templates/pandoc.epub $@.tex -o ../books/$@.epub --quiet
	ebook-convert ../books/$@.epub ../books/$@.mobi > /dev/null
	-rm $@.bak*

clean:
	-rm -r ../books

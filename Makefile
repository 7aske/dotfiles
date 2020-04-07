OUTDIR=~/.local/bin
INDIR=src

default_recipe: install

.PHONY: install
install:
	./install.sh $(INDIR) $(OUTDIR)

.PHONY: uninstall
uninstall:
	./uninstall.sh $(INDIR) $(OUTDIR)

add:
	touch src/$(s).sh
	chmod u+x src/$(s).sh

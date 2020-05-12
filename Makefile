OUTDIR=~/.local/bin
INDIR=src
STATUS_OUTDIR=~/.local/bin/statusbar
STATUS_INDIR=src/statusbar

default_recipe: install

.PHONY: install
install:
	./install.sh $(INDIR) $(OUTDIR)
	./install.sh $(STATUS_INDIR) $(STATUS_OUTDIR)

.PHONY: uninstall
uninstall:
	./uninstall.sh $(INDIR) $(OUTDIR)
	./uninstall.sh $(STATUS_INDIR) $(STATUS_OUTDIR)

add:
	touch src/$(s).sh
	chmod u+x src/$(s).sh

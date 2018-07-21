PORTDIR ?= $(shell portageq get_repo_path / gentoo)
LDAP_SHELL = sh -c
#LDAP_SHELL = ssh dev.gentoo.org
BINDIR = .
OUTDIR = .
TMPDIR = .

all: $(OUTDIR)/dev-timeline.html $(OUTDIR)/active-devs.html

fetch: $(PORTDIR)
	cd $(PORTDIR) && git fetch

qa-run:
	+$(MAKE) fetch
	+$(MAKE) all
	+$(MAKE) clean

$(OUTDIR)/dev-timeline.html: $(TMPDIR)/data-all-devs.txt $(BINDIR)/timeline.html.cpp
	cpp -P -DTITLE="Historical dev commit timeline:" \
		-DDATE=$$(date +%Y-%m-%d) \
		-DDATAFILE=\"$<\" < $(BINDIR)/timeline.html.cpp > $(TMPDIR)/dev-timeline.html.tmp
	mv $(TMPDIR)/dev-timeline.html.tmp $@
$(OUTDIR)/active-devs.html: $(TMPDIR)/data-active-devs.txt $(BINDIR)/timeline.html.cpp
	cpp -P -DTITLE="Active (committing) Gentoo dev timeline:" \
		-DDATE=$$(date +%Y-%m-%d) \
		-DDATAFILE=\"$<\" < $(BINDIR)/timeline.html.cpp > $(TMPDIR)/active-devs.html.tmp
	mv $(TMPDIR)/active-devs.html.tmp $@

$(TMPDIR)/data-all-devs.txt: $(TMPDIR)/aliases-all-devs.json
	( cd $(PORTDIR) && git log --format='%H %ct %ce %ae' ) | $(BINDIR)/gitlog2timeline.py --sort-earliest - $@ $<
$(TMPDIR)/data-active-devs.txt: $(TMPDIR)/aliases-active-devs.json
	( cd $(PORTDIR) && git log --format='%H %ct %ce %ae' ) | $(BINDIR)/gitlog2timeline.py --sort-latest --ldap-only - $@ $<

%.json: %.ldif
	$(BINDIR)/ldap2aliases.py $< $@

$(TMPDIR)/aliases-all-devs.ldif:
	$(LDAP_SHELL) "ldapsearch '(gentooStatus=*)' -Z uid mail gentooAlias -LLL" > $@
$(TMPDIR)/aliases-active-devs.ldif:
	$(LDAP_SHELL) "ldapsearch '(&(gentooAccess=git.gentoo.org/repo/gentoo.git)(gentooStatus=active))' -Z uid mail gentooAlias -LLL" > $@

clean:
	rm -f $(TMPDIR)/aliases-all-devs.ldif \
		$(TMPDIR)/aliases-all-devs.json \
		$(TMPDIR)/data-all-devs.txt \
		$(TMPDIR)/aliases-active-devs.ldif \
		$(TMPDIR)/aliases-active-devs.json \
		$(TMPDIR)/data-active-devs.txt

distclean: clean
	rm -f $(OUTDIR)/dev-timeline.html $(OUTDIR)/active-devs.html

.PHONY: all clean distclean fetch qa-run

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

$(TMPDIR)/data-all-devs.txt: $(OUTDIR)/dev-timeline.json
	$(BINDIR)/json2timeline.py $< $@
$(TMPDIR)/data-active-devs.txt: $(OUTDIR)/active-devs.json
	$(BINDIR)/json2timeline.py $< $@

$(OUTDIR)/dev-timeline.json: $(TMPDIR)/aliases-all-devs.json
	( cd $(PORTDIR) && git log --format='%H%x00%ct%x00%ce%x00%ae' ) | $(BINDIR)/gitlog2json.py --sort-earliest - $(TMPDIR)/dev-timeline.json.tmp $<
	mv $(TMPDIR)/dev-timeline.json.tmp $@
$(OUTDIR)/active-devs.json: $(TMPDIR)/aliases-active-devs.json
	( cd $(PORTDIR) && git log --format='%H%x00%ct%x00%ce%x00%ae' ) | $(BINDIR)/gitlog2json.py --sort-latest --ldap-only - $(TMPDIR)/active-devs.json.tmp $<
	mv $(TMPDIR)/active-devs.json.tmp $@

%.json: %.ldif
	$(BINDIR)/ldap2aliases.py $< $@

$(TMPDIR)/aliases-all-devs.ldif:
	$(LDAP_SHELL) "ldapsearch '(gentooStatus=*)' -x -Z uid mail gentooAlias -LLL" > $@
$(TMPDIR)/aliases-active-devs.ldif:
	$(LDAP_SHELL) "ldapsearch '(&(gentooAccess=git.gentoo.org/repo/gentoo.git)(gentooStatus=active))' -x -Z uid mail gentooAlias -LLL" > $@

clean:
	rm -f $(TMPDIR)/aliases-all-devs.ldif \
		$(TMPDIR)/aliases-all-devs.json \
		$(TMPDIR)/data-all-devs.txt \
		$(TMPDIR)/aliases-active-devs.ldif \
		$(TMPDIR)/aliases-active-devs.json \
		$(TMPDIR)/data-active-devs.txt

distclean: clean
	rm -f $(OUTDIR)/dev-timeline.html \
		$(OUTDIR)/dev-timeline.json \
		$(OUTDIR)/active-devs.html \
		$(OUTDIR)/active-devs.json

.PHONY: all clean distclean fetch qa-run

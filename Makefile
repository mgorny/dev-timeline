PORTDIR ?= $(shell portageq get_repo_path / gentoo)
LDAP_SHELL = sh -c
#LDAP_SHELL = ssh dev.gentoo.org

all: dev-timeline.html active-devs.html

dev-timeline.html: data-all-devs.txt timeline.html.cpp
	cpp -P -DTITLE="Historical dev commit timeline:" \
		-DDATE=$$(date +%Y-%m-%d) \
		-DDATAFILE=\"$<\" < timeline.html.cpp > $@.tmp
	mv $@.tmp $@
active-devs.html: data-active-devs.txt timeline.html.cpp
	cpp -P -DTITLE="Active (committing) Gentoo dev timeline:" \
		-DDATE=$$(date +%Y-%m-%d) \
		-DDATAFILE=\"$<\" < timeline.html.cpp > $@.tmp
	mv $@.tmp $@

data-all-devs.txt: aliases-all-devs.json
	( cd $(PORTDIR) && git log --format='%H %ct %ce %ae' ) | ./gitlog2timeline.py --sort-earliest - $@ $<
data-active-devs.txt: aliases-active-devs.json
	( cd $(PORTDIR) && git log --format='%H %ct %ce %ae' ) | ./gitlog2timeline.py --sort-latest --ldap-only - $@ $<

%.json: %.ldif
	./ldap2aliases.py $< $@

aliases-all-devs.ldif:
	$(LDAP_SHELL) "ldapsearch '(gentooStatus=*)' -Z uid mail gentooAlias -LLL" > $@
aliases-active-devs.ldif:
	$(LDAP_SHELL) "ldapsearch '(gentooStatus=active)' -Z uid mail gentooAlias -LLL" > $@

clean:
	rm -f dev-timeline.html aliases-all-devs.ldif aliases-all-devs.json data-all-devs.txt
	rm -f active-devs.html aliases-active-devs.ldif aliases-active-devs.json data-active-devs.txt

.PHONY: clean

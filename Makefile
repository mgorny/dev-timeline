PORTDIR ?= $(shell portageq get_repo_path / gentoo)

all: data-all-devs.txt data-active-devs.txt

data-all-devs.txt: aliases-all-devs.json
	( cd $(PORTDIR) && git log --format='%H %ct %ce %ae' ) | ./gitlog2timeline.py --sort-earliest - $@ $<
data-active-devs.txt: aliases-active-devs.json
	( cd $(PORTDIR) && git log --format='%H %ct %ce %ae' ) | ./gitlog2timeline.py --sort-latest --ldap-only - $@ $<

%.json: %.ldif
	./ldap2aliases.py $< $@

aliases-all-devs.ldif:
	ssh dev.gentoo.org "ldapsearch '(gentooStatus=*)' -Z uid mail gentooAlias -LLL" > $@
aliases-active-devs.ldif:
	ssh dev.gentoo.org "ldapsearch '(gentooStatus=active)' -Z uid mail gentooAlias -LLL" > $@

clean:
	rm -f aliases-all-devs.ldif aliases-all-devs.json data-all-devs.txt
	rm -f aliases-active-devs.ldif aliases-active-devs.json data-active-devs.txt

.PHONY: clean

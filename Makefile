PORTDIR ?= $(shell portageq get_repo_path / gentoo)

all: out.txt active-out.txt

out.txt: aliases.json
	( cd $(PORTDIR) && git log --format='%H %ct %ce %ae' ) | ./gitlog2timeline.py --sort-earliest - $@ $<
active-out.txt: active-aliases.json
	( cd $(PORTDIR) && git log --format='%H %ct %ce %ae' ) | ./gitlog2timeline.py --sort-latest --ldap-only - $@ $<

%.json: %.ldif
	./ldap2aliases.py $< $@

aliases.ldif:
	ssh dev.gentoo.org "ldapsearch '(gentooStatus=*)' -Z uid mail gentooAlias -LLL" > $@
active-aliases.ldif:
	ssh dev.gentoo.org "ldapsearch '(gentooStatus=active)' -Z uid mail gentooAlias -LLL" > $@

clean:
	rm -f aliases.ldif aliases.json out.txt
	rm -f active-aliases.ldif active-aliases.json active-out.txt

.PHONY: clean

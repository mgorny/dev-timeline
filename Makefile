aliases.json: aliases.ldif
	./ldap2aliases.py $< $@
aliases.ldif:
	ssh dev.gentoo.org "ldapsearch '(gentooStatus=*)' -Z uid mail gentooAlias -LLL" > $@
clean:
	rm -f aliases.ldif aliases.json

.PHONY: clean

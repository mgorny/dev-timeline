#!/usr/bin/env python
# Create aliases.json from LDIF
# (c) 2017 Michał Górny, 2-clause BSD licensed

import json
import os
import sys


def main(list_f='aliases.ldif', aliases_json='aliases.json'):
    aliases = {}
    with open(list_f) as f:
        ldif_data = f.read()

    for block in ldif_data.split('\n\n'):
        if not block.strip():
            continue
        uid = None
        mails = set()
        for l in block.splitlines():
            k, v = l.split(': ')
            if k == 'uid':
                uid = v
                mails.add(v + '@gentoo.org')
            elif k == 'mail':
                assert '@' in v
                mails.add(v)
            elif k == 'gentooAlias':
                mails.add(v + '@gentoo.org')
        assert uid
        assert mails
        for m in mails:
           aliases[m] = uid

    with open(aliases_json, 'w') as aliases_f:
        json.dump(aliases, aliases_f, indent=0, sort_keys=True)

    return 0


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))

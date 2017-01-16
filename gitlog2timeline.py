#!/usr/bin/env python

import collections
import datetime
import json
import sys


def fdate(ts):
    return datetime.datetime.fromtimestamp(ts, datetime.timezone.utc)


class DevRange:
    def __init__(self):
        self.min = None
        self.max = None

    def add(self, ts):
        if self.min is None: # == self.max is None
            self.min = self.max = ts
        elif ts < self.min:
            self.min = ts
        elif ts > self.max:
            self.max = ts

    def __repr__(self):
        return 'DevRange(%s, %s)' % (fdate(self.min), fdate(self.max))


def main(outpath):
    devs = collections.defaultdict(DevRange)

    with open('aliases.json') as f:
        aliases = json.load(f)

    for l in sys.stdin:
        spl = l.split()
        if len(spl) < 3: # some entries lack e-mail, for some reason
            continue
        h, ts, email = spl
        # map from email to canonical dev name
        # (including alternate aliases, emails)
        if email in aliases:
            uid = aliases[email]
        # devs not in LDAP?
        elif email.endswith('@gentoo.org'):
            uid = email[:-len('@gentoo.org')]
        # let's skip everyone else, for now
        else:
            continue
        devs[uid].add(int(ts))

    with open(outpath, 'w') as outf:
        for d, r in sorted(devs.items(), key=lambda x: x[1].min):
            outf.write('%s\t%s\t%s\n' % (d, fdate(r.min), fdate(r.max)))

    return 0


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))

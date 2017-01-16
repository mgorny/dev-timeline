#!/usr/bin/env python

import collections
import datetime
import json
import sys


def fdate(ts):
    return datetime.datetime.fromtimestamp(ts, datetime.timezone.utc)


def sdate(ts):
    d = fdate(ts)
    return (d.year, d.month, d.day)


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
        if len(spl) < 4: # some entries lack e-mail, for some reason
            continue
        h, ts, cemail, aemail = spl
        # use both committer & author:
        # - committer indicates developer activity (to merge stuff)
        # - author to 'fill' bars of pull request authors who became
        #   developers
        mails = set((cemail.lower(), aemail.lower()))
        for m in mails:
            # map from email to canonical dev name
            # (including alternate aliases, emails)
            if m in aliases:
                uid = aliases[m]
            # devs not in LDAP?
            elif m.endswith('@gentoo.org'):
                uid = m[:-len('@gentoo.org')]
            # let's skip everyone else, for now
            else:
                continue
            devs[uid.lower()].add(int(ts))

    with open(outpath, 'w') as outf:
        for d, r in sorted(devs.items(), key=lambda x: x[1].min):
#[ 'dev name' ,new Date(Y, M, D),new Date(Y, M, D) ],
            outf.write("[ %s, new Date(%d, %d, %d), new Date(%d, %d, %d) ],\n"
                    % (repr(d), *sdate(r.min), *sdate(r.max)))

    return 0


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))

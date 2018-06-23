#!/usr/bin/env python

import argparse
import collections
import datetime
import json
import sys


MAX_INACTIVITY = datetime.timedelta(days=90).total_seconds()


def fdate(ts):
    return datetime.datetime.fromtimestamp(ts, datetime.timezone.utc)


def sdate(ts):
    d = fdate(ts)
    return (d.year, d.month, d.day)


class DevRange:
    def __init__(self, minr=None, maxr=None):
        self.packed_ranges = []
        self.min = minr
        self.max = maxr

    def add(self, ts):
        if self.min is None: # == self.max is None
            self.min = self.max = ts
        elif ts < self.min:
            if self.min - ts > MAX_INACTIVITY:
                self.packed_ranges.append(DevRange(self.min, self.max))
                self.max = ts
            self.min = ts
        elif ts > self.max:
            self.max = ts

    @property
    def earliest(self):
        return self.min

    @property
    def latest(self):
        if self.packed_ranges:
            return self.packed_ranges[0].max
        else:
            return self.max

    def __repr__(self):
        return 'DevRange(%s, %s)' % (fdate(self.min), fdate(self.max))


def main():
    argp = argparse.ArgumentParser()

    argp.add_argument('--ldap-only', action='store_true', default=False,
        help='Ignore developers that are not present in LDAP')

    sortg = argp.add_mutually_exclusive_group()
    sortg.add_argument('--sort-earliest', action='store_true',
        help='Sort by earliest commit date')
    sortg.add_argument('--sort-latest', action='store_true',
        help='Sort by most recent commit date')
    sortg.add_argument('--sort-name', action='store_true',
        help='Sort by developer name')

    argp.add_argument('input', type=argparse.FileType('r'),
        help='Input file (output of git --format="%%H %%ct %%ce %%ae")')
    argp.add_argument('output', type=argparse.FileType('w'),
        help='Output file')
    argp.add_argument('aliases_json', type=argparse.FileType('r'),
        help='Aliases JSON file')

    vals = argp.parse_args()

    devs = collections.defaultdict(DevRange)
    aliases = json.load(vals.aliases_json)

    # --format='%H %ct %ce %ae'
    for l in vals.input:
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
            elif m.endswith('@gentoo.org') and not vals.ldap_only:
                uid = m[:-len('@gentoo.org')]
            # let's skip everyone else, for now
            else:
                continue
            devs[uid.lower()].add(int(ts))

    if vals.sort_latest:
        sort_key = lambda x: x[1].latest
    elif vals.sort_name:
        sort_key = lambda x: x[0]
    else:  # vals.sort_earliest
        sort_key = lambda x: x[1].earliest

    for d, bigrange in sorted(devs.items(), key=sort_key):
        for r in (*bigrange.packed_ranges, bigrange):
#[ 'dev name' ,new Date(Y, M, D),new Date(Y, M, D) ],
            vals.output.write("[ %s, new Date(%d, %d, %d), new Date(%d, %d, %d) ],\n"
                    % (repr(d), *sdate(r.min), *sdate(r.max)))

    return 0


if __name__ == '__main__':
    sys.exit(main())

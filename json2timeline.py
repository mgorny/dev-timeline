#!/usr/bin/env python

import argparse
import datetime
import json
import sys


def fdate(ts):
    return datetime.datetime.fromtimestamp(ts, datetime.timezone.utc)


def sdate(ts):
    d = fdate(ts)
    return (d.year, d.month, d.day)


def main():
    argp = argparse.ArgumentParser()

    argp.add_argument('input', type=argparse.FileType('r'),
        help='Input JSON file')
    argp.add_argument('output', type=argparse.FileType('w'),
        help='Output file')

    vals = argp.parse_args()

    data = json.load(vals.input)

    for d, ranges in data:
        for commits, start, end in ranges:
#[ 'dev name', '%d commits' ,new Date(Y, M, D),new Date(Y, M, D) ],
            vals.output.write("[ %s, '%d commits', new Date(%d, %d, %d), new Date(%d, %d, %d) ],\n"
                    % (repr(d), commits, *sdate(start), *sdate(end)))

    return 0


if __name__ == '__main__':
    sys.exit(main())

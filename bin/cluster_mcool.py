#!/usr/bin/env python

import glob
import os

import argparse as ap

from spritefridge.combine.ioutils import clustersize_from_filename
from cooler import fileops


def parse_args():
    parser = ap.ArgumentParser()
    parser.add_argument(
        '--input',
        '-i',
        help = 'path to directory containig clustersize coolers to merge. The name of the coolers must contain the clustersize _(?P<cs>[0-9]+)_',
        required = True
    )
    parser.add_argument(
        '--output',
        '-o',
        required = True,
        help = 'name of the outputfile to write'
    )
    return parser.parse_args()


def main():
    args = parse_args()
    for coolfile in glob.glob(args.input + '/*'):
        clustersize = clustersize_from_filename(
            os.path.basename(coolfile)
        )
        fileops.cp(
            coolfile,
            args.output + f'::/clustersize/{clustersize}'
        )


if __name__ == '__main__':
    main()
    
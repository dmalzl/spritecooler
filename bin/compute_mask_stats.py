#!/usr/bin/env python

import pysam as ps
import argparse as ap


def parse_args():
    parser = ap.ArgumentParser()
    parser.add_argument(
        '--input',
        '-i',
        requried = True,
        help = 'unfiltered bam file'
    )
    parser.add_argument(
        '--masked',
        '-m',
        requried = True,
        help = 'filtered bam file'
    )
    parser.add_argument(
        '--output',
        '-o',
        required = True,
        help = 'file to write stats to'
    )
    return parser.parse_args()


def alignment_counts(bamfile):
    with ps.AlignmentFile(bamfile) as bam:
        count = bam.count(until_eof = True)
    
    return count


def main():
    args = parse_args()
    unfiltered = alignment_counts(args.input)
    filtered = alignment_counts(args.masked)
    n_masked = unfiltered - filtered
    with open(args.output, 'w') as stats:
        stats.write(f'valid\t{filtered}')
        stats.write(f'masked\t{n_masked}')


if __name__ == '__main__':
    main()
    
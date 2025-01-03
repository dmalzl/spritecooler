#!/usr/bin/env python

import argparse as ap
import pysam as ps
import logging

logging.basicConfig(
    format='%(asctime)s - %(message)s',
    level=logging.INFO
)

def parse_args():
    parser = ap.ArgumentParser()
    parser.add_argument(
        '-i',
        '--input',
        required = True,
        help = 'BAM file to filter'
    )
    parser.add_argument(
        '-q',
        '--minq',
        default = 20,
        type = int,
        help = 'minimum required mapping quality for an alignment to be considered valid'
    )
    parser.add_argument(
        '-o',
        '--outprefix',
        required = True,
        help = 'prefix of the files to write valid alignments and stats to'
    )
    return parser.parse_args()


def count(d, name):
    if name not in d:
        d[name] = 0
    
    d[name] += 1


def main():
    args = parse_args()

    min_mapq = args.minq
    min_mapq_key = f'mapq_smaller_{min_mapq}'
    statsheader = ['unique', 'multimapping', min_mapq_key, 'unmapped']
    stats = {k: 0 for k in statsheader}
    alignments_per_read = {}
    
    inbam = ps.AlignmentFile(args.input, 'rb')
    outbam = ps.AlignmentFile(
        args.outprefix + '.filtered.bam', 
        'wb', 
        template = inbam
    )
    nprocessed = 0
    for alignment in inbam.fetch(until_eof = True):
        name = alignment.query_name
        nprocessed += 1

        if not nprocessed % 1e5:
            logging.info(f'processed {nprocessed} alignments')

        if not alignment.is_mapped:
            stats['unmapped'] += 1
            continue

        if not alignment.mapping_quality < min_mapq:
            stats[min_mapq_key] += 1
            continue
        
        if alignment.is_secondary:
            count(alignments_per_read, name)
            continue

        count(alignments_per_read, name)
        outbam.write(alignment)

    inbam.close()
    outbam.close()

    for alignment_count in alignments_per_read.values():
        if alignment_count > 1:
            stats['multimapping'] += 1
            continue

        stats['unique'] += 1

    with open(args.outprefix + '.stats.tsv', 'w') as statsfile:
        for k in statsheader:
            statsfile.write(
                f'{k}\t{stats[k]}\n'
            )
            

if __name__ == '__main__':
    main()

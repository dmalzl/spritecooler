#!/usr/bin/env python

import argparse as ap


def parse_args():
    parser = ap.ArgumentParser()
    parser.add_argument(
        '-i',
        '--input',
        required = True,
        help = 'tab-separated file containing DPM sequences. has to have columns category, barcodename, barcodesequence in this order'
    )
    parser.add_argument(
        '-o',
        '--outfile',
        required = True,
        help = 'name of the output fasta'
    )
    return parser.parse_args()


def read_dpms(barcodefile):
    dpms = {}
    with open(barcodefile, 'r') as file:
        for line in file:
            cat, name, seq = line.rstrip().split('\t')
            if cat != 'DPM':
                continue

            dpms[name] = seq
    
    return dpms


def write_dpm_fasta(dpms, outfile):
    with open(outfile, 'w') as file:
        for name, seq in dpms.items():
            file.write(f'>{name}\n{seq}\n')


def main():
    args = parse_args()
    dpms = read_dpms(args.input)
    write_dpm_fasta(
        dpms,
        args.outfile
    )


if __name__ == '__main__':
    main()

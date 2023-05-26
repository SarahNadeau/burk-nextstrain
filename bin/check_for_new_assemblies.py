#!/usr/bin/python3

import argparse
import os
import pandas as pd

# Parse command-line arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--assembly_table", 
    help="NCBImetaExport output *_Assembly.txt")
parser.add_argument(
    "--assembly_dir", 
    help="Directory with cached assembly files.")
parser.add_argument(
    "--max_assemblies", 
    type=int,
    default=None,
    help="Maximum number of assemblies for analysis.")
args = parser.parse_args()

# Load assemlby table
assembly_table = pd.read_table(args.assembly_table)

# Load existing files
try:
    cached_assemblies = os.listdir(args.assembly_dir)
except FileNotFoundError:
    print("No locally stored assemblies found in '" + args.assembly_dir + "'.")
    cached_assemblies = []

# Filter table to new assemblies only
new_assembly_table = assembly_table.loc[~assembly_table['AssemblyAccession'].isin(cached_assemblies)]

print("Found " + str(new_assembly_table.shape[0]) + " new assemblies.")

# Limit to maximum number of assemblies if specified
if args.max_assemblies is not None:
    n_assemblies_to_download = min(
        max(args.max_assemblies - len(cached_assemblies), 0), 
        new_assembly_table.shape[0])
    new_assembly_table = new_assembly_table.head(n_assemblies_to_download)
    print("Adding only " + str(new_assembly_table.shape[0]) + " assemblies to download list based on max_assemblies parameter.")

# Write out list of assemblies to download
new_assembly_table['AssemblyAccession'].to_csv(
    'assemblies_to_download.txt', 
    index=False, 
    header=False,
    sep='\t')

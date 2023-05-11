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
args = parser.parse_args()

# Load assemlby table
assembly_table = pd.read_table(args.assembly_table)

# Load existing files
cached_assemblies = os.listdir(args.assembly_dir)

# Filter table to new assemblies only
new_assembly_table = assembly_table.loc[~assembly_table['AssemblyAccession'].isin(cached_assemblies)]

# Write out new assemlby table
new_assembly_table.to_csv('new_assembly_table.txt', index=False, sep='\t')

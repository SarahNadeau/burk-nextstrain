#!/usr/bin/python3

import argparse
import pandas as pd
import urllib.request
import os

# Parse command-line arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--assembly_table", 
    help="Tab-delimited table with columns 'AssemblyBioSampleAccession' and 'AssemblyFTPRefSeq'.")
parser.add_argument(
    "--output_dir", 
    help="Directory to download assembly files to.")
parser.add_argument(
    "--max_assemblies", 
    default = 9999,
    type = int,
    required=False,
    help="Maximum number of assemblies to store.")
args = parser.parse_args()

# Load table
assembly_table = pd.read_csv(args.assembly_table, sep="\t")
assembly_table.set_index('AssemblyBioSampleAccession', inplace=True)

# Filter to only new assemblies
existing_assemblies = os.listdir(args.output_dir)
print(existing_assemblies)
new_assemblies = set(assembly_table.index.values) - set(existing_assemblies)

if len(existing_assemblies) > args.max_assemblies:
    raise ValueError('More than ' + str(args.max_assemblies) + ' found already. Raise max_assemblies to download more.')
if len(existing_assemblies) + len(new_assemblies) > args.max_assemblies:
    n_to_download = args.max_assemblies - len(existing_assemblies)
    Warning('Only downloading ' + str(n_to_download) + ' out of ' + str(len(new_assemblies)) + ' assemblies. Raise max_assemblies to download more.')
    new_assemblies = list(new_assemblies)[0:n_to_download]

print("Preparing to download " + str(len(new_assemblies)) + " assemblies")

# Download assemblies
for accession in new_assemblies:
    ftp_link = assembly_table.loc[[accession]]['AssemblyFTPRefSeq'].iloc[0]
    filepath = args.output_dir + "/" + accession
    print("Downloading " + ftp_link + " to " + filepath)
    local_filename, headers = urllib.request.urlretrieve(ftp_link, filepath)

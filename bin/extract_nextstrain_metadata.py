#!/usr/bin/python3

import argparse
import sqlite3
import pandas as pd
from datetime import datetime

# Parse command-line arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--database_file", 
    help="SQLite database file produced by NCBImeta.")
parser.add_argument(
    "--output", 
    help="Fileto save (CSV-formatted) nextstrain metadata to.")
args = parser.parse_args()

# Connect to database
db_connection = sqlite3.connect(args.database_file)
# db_cursor = db_connection.cursor()

# Query database
query = "SELECT * FROM Assembly a LEFT JOIN BioSample b ON a.AssemblyBioSampleID = b.BioSample_id"
table = pd.read_sql_query(query, db_connection)
nextstrain_metadata = {
    "strain": table['AssemblyAccession'],
    "date": table['BioSampleCollectionDate'],
    "date_submitted": table['AssemblySubmissionDate'],
    "region": table['BioSampleGeographicLocation'],
    "host": table['BioSampleHost']
}

# Parse dates, function inspired by https://github.com/nextstrain/ncov-ingest/tree/master
def format_date(date_string: str) -> str:
    if date_string is None:
        return '?'
    try:
        return datetime.strptime(date_string, '%Y-%m-%d').strftime('%Y-%m-%d')
    except ValueError:
        try:
            return datetime.strptime(date_string, '%Y-%m').strftime('%Y-%m-XX')
        except ValueError:
            try:
                return datetime.strptime(date_string, '%Y').strftime('%Y-XX-XX')
            except:
                return '?'

# Format nicely
for column in ['date', 'date_submitted']:
    if column in nextstrain_metadata:
        new_dates = [None] * len(nextstrain_metadata[column])
        for i, date in enumerate(nextstrain_metadata[column]):
            new_date = format_date(date)
            new_dates[i] = new_date
        nextstrain_metadata[column] = new_dates
nextstrain_table = pd.DataFrame(nextstrain_metadata)
nextstrain_table.fillna('?', inplace=True)

# Write out nextstrain metadata
nextstrain_table.to_csv(args.output, index=False)

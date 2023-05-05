process BUILD_DATABASE {
    publishDir "data/$workflow.start"
    container "snads/ncbimeta:0.8.3"
 
    input:
        path config
        val api_key
        val ncbi_email

    output:
        path "ncbimeta/"
        path "ncbimeta/*.sqlite", emit: db_file

    shell:
    """
    NCBImeta \
        --flat \
        --config !{config} \
        --api !{api_key} \
        --email !{ncbi_email}
    """
}

process EXPORT_DATABASE_TABLE {
    publishDir "data/$workflow.start"
    container "snads/ncbimeta:0.8.3"

    input:
        path db_file

    output:
        path "*_Assembly.txt", emit: assembly_table
    
    shell:
    """
    NCBImetaExport \
        --database !{db_file} \
        --outputdir .
    """
}

process DOWNLOAD_ASSEMBLIES {
    publishDir "data/"
    container "staphb/ncbi-datasets:14.7.0"

    input:
        path assembly_table
        val api_key

    output:
        path "ncbi_dataset/"

    shell:
    """
    # AssemblyAccession is 3rd colum of table, ignore header line
    awk 'NR < 2 {next}; {print \$3 }' !{assembly_table} > assembly_accessions.txt

    # Download assemblies
    datasets download genome accession \
        --inputfile assembly_accessions.txt \
        --api-key !{api_key}
    unzip ncbi_dataset.zip
    """
}
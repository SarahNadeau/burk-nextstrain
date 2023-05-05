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
    publishDir "data/assemblies"

    input:
        path assembly_table

    output:
        path "*.fna.gz"

    shell:
    """
    download_assemblies.py --assembly_table !{assembly_table} --output_dir '.'

    # Extract and rename fasta files
    LEFT OFF HERE!
    """
}
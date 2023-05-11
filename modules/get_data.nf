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

    stub:
    """
    mkdir ncbimeta
    cp ${projectDir}/assets/burk_data/* ncbimeta/
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
    publishDir (path: "data/", mode: 'copy')
    container "staphb/ncbi-datasets:14.7.0"

    input:
        path assembly_table
        val api_key
        val max_assemblies

    output:
        path "assemblies", emit: assembly_dir

    shell:
    """
    # AssemblyAccession is 3rd colum of table, ignore header line
    awk 'NR < 2 {next}; {print \$3 }' !{assembly_table} > assembly_accessions.txt

    # Limit number of assemblies if desired
    if [[ !{max_assemblies} != 'Inf' ]]; do
        head -n !{max_assemblies} assembly_accessions_tmp.txt
        mv assembly_accessions_tmp.txt assembly_accessions.txt
    done

    # Download assemblies
    datasets download genome accession \
        --inputfile assembly_accessions.txt \
        --api-key !{api_key}
    unzip ncbi_dataset.zip

    # Remove directory structure
    mkdir assemblies/
    for DIR in ncbi_dataset/data/*/; do
        mv \$DIR/*.fna assemblies/
        rm -r \$DIR
    done

    # Rename to assembly accession by removing everything after second-to-last underscore
    # Assumes filenames like GCA_002587985.1_ASM258798v1_genomic.fna > GCA_002587985.1
    cd assemblies/
    for FILE in *.fna; do
        mv -i "\$FILE" "\${FILE%_*_*}"
    done
    """
}
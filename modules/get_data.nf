process BUILD_DATABASE {
    publishDir "${params.output_dir}"
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
    cp ${projectDir}/assets/burk_data/ncbimeta/* ncbimeta/
    """
}

process EXPORT_DATABASE_TABLE {
    publishDir "${params.output_dir}"
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

process CHECK_FOR_NEW_ASSEMBLIES {
    publishDir (path: "${params.output_dir}", mode: 'copy')

    input:
        path assembly_table
        path data_dir
        val max_assemblies

    output:
        path "assemblies_to_download.txt", emit: assemblies_to_download

    shell:
    """
    if [[ '!{max_assemblies}' == 'Inf' ]]; then
        check_for_new_assemblies.py \
            --assembly_table !{assembly_table} \
            --assembly_dir !{data_dir}
    else
        check_for_new_assemblies.py \
            --assembly_table !{assembly_table} \
            --max_assemblies !{max_assemblies} \
            --assembly_dir !{data_dir}
    fi
    """
}

process DOWNLOAD_ASSEMBLIES {
    publishDir (path: "${params.output_dir}", mode: 'copy')
    container "staphb/ncbi-datasets:14.7.0"

    input:
        path assembly_list
        val api_key

    output:
        path "new_assemblies", emit: new_assembly_dir

    shell:
    """
    mkdir new_assemblies

    # If the file contains new assemblies to download, download them
    if [[ -s !{assembly_list} ]]; then
        # Download assemblies
        datasets download genome accession \
            --inputfile !{assembly_list} \
            --api-key !{api_key}
        unzip ncbi_dataset.zip

        # Remove directory structure
        # Rename to assembly accession by removing everything after second-to-last underscore
        # Assumes filenames like GCA_002587985.1_ASM258798v1_genomic.fna > GCA_002587985.1
        for DIR in ncbi_dataset/data/*/; do
            mv \$DIR/*.fna new_assemblies
            for FILE in new_assemblies/*.fna; do
                mv -i "\$FILE" "\${FILE%_*_*}"
            done
            rm -r \$DIR
        done

    # If no assemblies in file, don't download anything and warn user
    else 
        echo "No new assemblies found to download"
    fi
    """ 
}
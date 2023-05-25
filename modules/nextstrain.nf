// Generate nextstrain-format metadata from NCBImeta SQLite database
process EXPORT_NEXTSTRAIN_METADATA {
    publishDir(path: "${params.output_dir}/nextstrain", mode: 'copy')

    input:
        path db_file
    
    output:
        path "nextstrain_metadata.csv", emit: metadata
    
    shell:
    """
    extract_nextstrain_metadata.py \
        --database_file !{db_file} \
        --output nextstrain_metadata.csv
    """

}

// Get proximity list of most related context sequences for a focal set
process PROXIMITIES {
    container 'snads/augur:21.1.0'
    publishDir(path: "${params.output_dir}/nextstrain", mode: 'copy')

    label "process_medium"

    input: 
        path context_alignment
        path focal_alignment
        path reference

    output:
        path "proximities.tsv"

    script:
        """
        set -eu
        
        REF_NAME="\$(grep '^>' ${reference} | sed 's/>//')"
        
        git clone https://github.com/nextstrain/ncov.git ./ncov
        
        /Python-3.8.0/python ./ncov/scripts/get_distance_to_focal_set.py \
            --alignment ${context_alignment} \
            --focal-alignment ${focal_alignment} \
            --reference ${reference} \
            --ignore-seqs \${REF_NAME} \
            --output proximities.tsv
        """
}

// Get priority ranking of most related context sequences for a focal set
process PRIORITIES {
    container 'snads/augur:21.1.0'
    publishDir(path: "${params.output_dir}/nextstrain", mode: 'copy')

    label "process_medium"

    input: 
        path context_alignment
        path proximities

    output:
        path "priorities.tsv", emit: priorities
        path "index.tsv", emit: index

    shell:
        """
        set -eu
        git clone https://github.com/nextstrain/ncov.git ./ncov

        augur index \
            --sequences !{context_alignment} \
            --output index.tsv

        /Python-3.8.0/python ./ncov/scripts/priorities.py \
            --sequence-index index.tsv \
            --proximities !{proximities} \
            --crowding-penalty 0 \
            --output priorities.tsv
        """
}

// run the nextstrain workflow, including inferring ancestral traits and export to auspice for visualization
// don't refine the tree with any special options
process NEXTSTRAIN_AUGUR_TRAITS {
    container 'snads/augur:21.1.0'
    publishDir(path: "${params.output_dir}/nextstrain", mode: 'copy')

    label "proces_medium"

    input: 
        path metadata
        path tree
        path snp_alignment
        val traits

    output:
        path "auspice.json", emit: auspice_json
        path "traits.json"
        path "branch_lengths.json"

    shell:
        """
        set -eu

        augur refine \
            --tree !{tree} \
            --output-tree tree_augur.nwk \
            --output-node-data branch_lengths.json

        augur traits \
            --tree tree_augur.nwk \
            --metadata !{metadata} \
            --output-node-data traits.json \
            --confidence \
            --columns !{traits}

        augur export v2 \
            --tree tree_augur.nwk \
            --metadata !{metadata} \
            --node-data branch_lengths.json \
                        traits.json \
            --color-by-metadata !{traits} \
            --output auspice.json
        """
}

// Generate nextstrain-format metadata from NCBImeta SQLite database
process EXPORT_NEXTSTRAIN_METADATA {
    publishDir(path: "${params.output_folder}/nextstrain", mode: 'copy')

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
    publishDir(path: "${params.output_folder}/nextstrain", mode: 'copy')

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
    publishDir(path: "${params.output_folder}/nextstrain", mode: 'copy')

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

// run the whole nextstrain workflow, including export to auspice for visualization
process NEXTSTRAIN_AUGUR_VCF {
    container 'snads/augur:21.1.0'
    publishDir(path: "${params.output_folder}/nextstrain", mode: 'copy')

    label "proces_medium"

    input: 
        path metadata
        path alignment
	    path reference
        val traits
        val refine_params

    output:
        path "auspice.json", emit: auspice_json
        path "tree_raw.nwk"
        path "tree.nwk"
        path "traits.json"
        path "branch_lengths.json"

    shell:
        """
        set -eu

        augur tree \
            --alignment !{alignment} \
	        --vcf-reference !{reference} \
            --output tree_raw.nwk

        augur refine \
            --tree tree_raw.nwk \
            --alignment !{alignment} \
	        --vcf-reference !{reference} \
            --metadata !{metadata} \
            --output-tree tree.nwk \
            --output-node-data branch_lengths.json \
            !{refine_params}

        augur traits \
            --tree tree.nwk \
            --metadata !{metadata} \
            --output-node-data traits.json \
            --confidence \
            --columns !{traits}

        # skipping reconstruction of nucleotide and amino acid mutations

        augur export v2 \
            --tree tree.nwk \
            --metadata !{metadata} \
            --node-data branch_lengths.json \
                        traits.json \
            --color-by-metadata !{traits} \
            --output auspice.json
        """
}

process NEXTSTRAIN_AUGUR {
    container 'snads/augur:21.1.0'
    publishDir(path: "${params.output_folder}/nextstrain", mode: 'copy')

    label "process_medium"

    input:
        path metadata
        path alignment
        val traits
        val refine_params

    output:
        path "auspice.json", emit: auspice_json
        path "tree_raw.nwk"
        path "tree.nwk"

    shell:
        """
        set -eu

        augur tree \
            --alignment !{alignment} \
            --output tree_raw.nwk

        augur refine \
            --tree tree_raw.nwk \
            --alignment !{alignment} \
            --metadata !{metadata} \
            --output-tree tree.nwk \
            --output-node-data branch_lengths.json \
            !{refine_params}

        augur traits \
            --tree tree.nwk \
            --metadata !{metadata} \
            --output-node-data traits.json \
            --columns !{traits} \
            --confidence

        # skipping reconstruction of nucleotide and amino acid mutations

        augur export v2 \
            --tree tree.nwk \
            --metadata !{metadata} \
            --node-data branch_lengths.json \
                        traits.json \
            --color-by-metadata !{traits} \
            --output auspice.json
        """
}

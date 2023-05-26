process PARSNP {
    publishDir "${params.output_dir}/align"
    container 'staphb/parsnp:1.5.6'

    label "process_medium"

    input:
        path new_assembly_dir
        path data_dir
        path reference

    output:
        path "parsnp.vcf", emit: vcf
        path "parsnp.tree", emit: tree
        path "snp_alignment.fasta", emit: snp_alignment
        path "*.log"

    shell:
        """
        # Align genomes, build tree (uses RAxML by default)
        parsnp \
            -c \
            -r !{reference} \
            --sequences !{data_dir} !{new_assembly_dir} \
            --threads !{task.cpus} \
            --output-dir parsnp \
            --vcf
        mv parsnp/* .

        # Extract SNP alignment from harvest file
        harvesttools -i parsnp.ggr -S snp_alignment.fasta
        """
}
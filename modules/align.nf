process ALIGN_ASSEMBLIES_PARSNP {
    publishDir "${params.output_dir}/align"
    container 'staphb/parsnp:1.5.6'

    label "process_medium"

    input:
        val ready_signal
        path assembly_dir
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
            --sequences !{assembly_dir} \
            --threads !{task.cpus} \
            --output-dir parsnp \
            --vcf
        mv parsnp/* .

        # Extract SNP alignment from harvest file
        harvesttools -i parsnp.ggr -S snp_alignment.fasta
        """

    
}
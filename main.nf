nextflow.enable.dsl = 2

// Default parameter values
params.api_key = ''
params.ncbi_email = ''
params.ncbimeta_config = 'ncbimeta/test.yaml'
params.reference = 'assets/test_data/reference.fasta'
params.data_dir = 'data'  // where to download assemblies to, can also include cached assemblies you want to include in analysis
params.output_dir = "output_${workflow.start}" // where to output intermediate output, auspic JSON to
params.traits = 'region host' // metadata column names to reconstruct ancestral traits for
params.max_assemblies = 'Inf' // maximum number of assemblies to download, regardless of how many match NCBI query

// Import modules
include { 
    BUILD_DATABASE;
    EXPORT_DATABASE_TABLE;
    CHECK_FOR_NEW_ASSEMBLIES;
    DOWNLOAD_ASSEMBLIES } from './modules/get_data.nf'
include {
    ALIGN_ASSEMBLIES_PARSNP } from './modules/align.nf'
include {
    EXPORT_NEXTSTRAIN_METADATA;
    NEXTSTRAIN_AUGUR_TRAITS } from './modules/nextstrain.nf'

// Run workflow
workflow {

    ncbimeta_config = channel.fromPath(params.ncbimeta_config)
    reference = channel.fromPath(params.reference)
    data_dir = channel.fromPath(params.data_dir)

    BUILD_DATABASE(
        ncbimeta_config,
        params.api_key,
        params.ncbi_email)

    EXPORT_DATABASE_TABLE(BUILD_DATABASE.out.db_file)

    CHECK_FOR_NEW_ASSEMBLIES(
        EXPORT_DATABASE_TABLE.out.assembly_table,
        data_dir,
        params.max_assemblies)

    DOWNLOAD_ASSEMBLIES(
        CHECK_FOR_NEW_ASSEMBLIES.out.assemblies_to_download,
        params.api_key,
        data_dir)

    ALIGN_ASSEMBLIES_PARSNP(
        DOWNLOAD_ASSEMBLIES.out.ready_signal,
        data_dir,
        reference)

    EXPORT_NEXTSTRAIN_METADATA(BUILD_DATABASE.out.db_file)

    NEXTSTRAIN_AUGUR_TRAITS(
        EXPORT_NEXTSTRAIN_METADATA.out.metadata,
        ALIGN_ASSEMBLIES_PARSNP.out.tree,
        ALIGN_ASSEMBLIES_PARSNP.out.snp_alignment,
        params.traits)       

}
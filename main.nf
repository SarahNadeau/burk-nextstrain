nextflow.enable.dsl = 2

// Default parameter values
params.api_key = ''
params.ncbi_email = ''
params.ncbimeta_config = 'ncbimeta/test.yaml'
params.reference = 'assets/test_data/reference.fasta'
params.local_assemblies_to_include = 'None'  // directory with locally stored assemblies you want to include in analysis
params.output_dir = "output_${workflow.start}" // where to output additionally downloaded assemblies, intermediate output, auspice JSON to
params.traits = 'region host' // metadata column names to reconstruct ancestral traits for
params.max_assemblies = 'Inf' // maximum number of assemblies to analyze, regardless of how many match NCBI query (only applies to NCBI-downloaded assemblies, all local assemblies to include will be analyzed)

// Import modules
include { 
    BUILD_DATABASE;
    EXPORT_DATABASE_TABLE;
    CHECK_FOR_NEW_ASSEMBLIES;
    DOWNLOAD_ASSEMBLIES } from './modules/get_data.nf'
include {
    PARSNP } from './modules/align_and_tree.nf'
include {
    EXPORT_NEXTSTRAIN_METADATA;
    NEXTSTRAIN_AUGUR_TRAITS } from './modules/nextstrain.nf'

// Run workflow
workflow {

    ncbimeta_config = channel.fromPath(params.ncbimeta_config)
    reference = channel.fromPath(params.reference)
    local_assemblies_to_include = channel.fromPath(params.local_assemblies_to_include)

    BUILD_DATABASE(
        ncbimeta_config,
        params.api_key,
        params.ncbi_email)

    EXPORT_DATABASE_TABLE(BUILD_DATABASE.out.db_file)

    CHECK_FOR_NEW_ASSEMBLIES(
        EXPORT_DATABASE_TABLE.out.assembly_table,
        local_assemblies_to_include,
        params.max_assemblies)

    DOWNLOAD_ASSEMBLIES(
        CHECK_FOR_NEW_ASSEMBLIES.out.assemblies_to_download,
        params.api_key)

    PARSNP(
        DOWNLOAD_ASSEMBLIES.out.new_assembly_dir,
        local_assemblies_to_include,
        reference)

    EXPORT_NEXTSTRAIN_METADATA(BUILD_DATABASE.out.db_file)

    NEXTSTRAIN_AUGUR_TRAITS(
        EXPORT_NEXTSTRAIN_METADATA.out.metadata,
        PARSNP.out.tree,
        PARSNP.out.snp_alignment,
        params.traits)       

}
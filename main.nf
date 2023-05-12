nextflow.enable.dsl = 2

// Default parameter values
params.api_key = ''
params.ncbi_email = ''
params.ncbimeta_config = 'ncbimeta/test.yaml'
params.reference = 'assets/test_data/reference.fasta'
params.output_folder = 'test_results'
params.traits = 'region host'
params.augur_refine_params = '--root reference.fasta.ref'
params.max_assemblies = 'Inf' // maximum number of assemblies to download, regardless of how many match NCBI query
params.cached_assembly_dir = false // directory with assemblies you want to include

// Import modules
include { 
    BUILD_DATABASE;
    EXPORT_DATABASE_TABLE;
    CHECK_FOR_NEW_ASSEMBLIES;
    DOWNLOAD_ASSEMBLIES;
    DOWNLOAD_ASSEMBLIES_TO_CACHE } from './modules/get_data.nf'
include {
    ALIGN_ASSEMBLIES_PARSNP } from './modules/align.nf'
include {
    EXPORT_NEXTSTRAIN_METADATA;
    NEXTSTRAIN_AUGUR_VCF } from './modules/nextstrain.nf'

// Run workflow
workflow {

    ncbimeta_config = channel.fromPath(params.ncbimeta_config)
    reference = channel.fromPath(params.reference)

    BUILD_DATABASE(
        ncbimeta_config,
        params.api_key,
        params.ncbi_email)

    EXPORT_DATABASE_TABLE(BUILD_DATABASE.out.db_file)

    if (params.cached_assembly_dir) {
        cached_assembly_dir = channel.fromPath(params.cached_assembly_dir)

        CHECK_FOR_NEW_ASSEMBLIES(
            EXPORT_DATABASE_TABLE.out.assembly_table,
            cached_assembly_dir)

        DOWNLOAD_ASSEMBLIES_TO_CACHE(
            CHECK_FOR_NEW_ASSEMBLIES.out.new_assembly_table,
            params.api_key,
            params.max_assemblies)

        ALIGN_ASSEMBLIES_PARSNP(
            DOWNLOAD_ASSEMBLIES_TO_CACHE.out.ready_signal,
            cached_assembly_dir,
            reference)
            
    } else {
        DOWNLOAD_ASSEMBLIES(
            EXPORT_DATABASE_TABLE.out.assembly_table,
            params.api_key,
            params.max_assemblies)
        
        ALIGN_ASSEMBLIES_PARSNP(
            DOWNLOAD_ASSEMBLIES.out.ready_signal,
            DOWNLOAD_ASSEMBLIES.out.assembly_dir,
            reference)
    }

    EXPORT_NEXTSTRAIN_METADATA(BUILD_DATABASE.out.db_file)

    NEXTSTRAIN_AUGUR_VCF(
        EXPORT_NEXTSTRAIN_METADATA.out.metadata,
        ALIGN_ASSEMBLIES_PARSNP.out.vcf,
	    reference,
        params.traits,
        params.augur_refine_params)
}
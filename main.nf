nextflow.enable.dsl = 2

// Default parameter values
params.api_key = ''
params.ncbi_email = ''
params.ncbimeta_config = 'ncbimeta/test.yaml'
params.reference = 'assets/test_data/reference.fasta'
params.output_folder = 'test_results'
params.traits = 'region host'
params.augur_refine_params = '--root reference.fasta.ref'

// Import modules
include { 
    BUILD_DATABASE;
    EXPORT_DATABASE_TABLE;
    DOWNLOAD_ASSEMBLIES } from './modules/get_data.nf'
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

    DOWNLOAD_ASSEMBLIES(
        EXPORT_DATABASE_TABLE.out.assembly_table,
        params.api_key)

    ALIGN_ASSEMBLIES_PARSNP(
        DOWNLOAD_ASSEMBLIES.out.assembly_dir,
        reference)

    EXPORT_NEXTSTRAIN_METADATA(BUILD_DATABASE.out.db_file)

    NEXTSTRAIN_AUGUR_VCF(
        EXPORT_NEXTSTRAIN_METADATA.out.metadata,
        ALIGN_ASSEMBLIES_PARSNP.out.vcf,
	    reference,
        params.traits,
        params.augur_refine_params)
}
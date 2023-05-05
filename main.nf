nextflow.enable.dsl = 2

// Default parameter values
params.api_key = ''
params.ncbi_email = ''
params.ncbimeta_config = 'ncbimeta/test.yaml'

// Import modules
include { 
    BUILD_DATABASE;
    EXPORT_DATABASE_TABLE;
    DOWNLOAD_ASSEMBLIES } from './modules/get_data.nf'

// Run workflow
workflow {

    ncbimeta_config = channel.fromPath(params.ncbimeta_config)

    BUILD_DATABASE(
        ncbimeta_config,
        params.api_key,
        params.ncbi_email)

    EXPORT_DATABASE_TABLE(BUILD_DATABASE.out.db_file)

    DOWNLOAD_ASSEMBLIES(EXPORT_DATABASE_TABLE.out.assembly_table)

    // TODO: build alignment

    // TODO: nextstrain build
}
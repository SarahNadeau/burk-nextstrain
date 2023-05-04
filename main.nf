nextflow.enable.dsl = 2

// Default parameter values
params.api_key = ''
params.ncbi_email = ''
params.ncbimeta_config = 'ncbimeta/test.yaml'

// Import modules
include { BUILD_DATABASE } from './modules/get_data.nf'

// Run workflow
workflow {

    ncbimeta_config = channel.fromPath(params.ncbimeta_config)

    BUILD_DATABASE(
        ncbimeta_config,
        params.api_key,
        params.ncbi_email
    )

    // DOWNLOAD_ASSEMBLIES()

    // TODO: build alignment

    // TODO: nextstrain build
}
process BUILD_DATABASE {
    publishDir "ncbimeta"
    container "snads/ncbimeta:0.8.3"
 
    input:
        path config
        val api_key
        val ncbi_email

    output:
        path "ncbimeta/"

    shell:
    """
    NCBImeta \
        --config !{config} \
        --api !{api_key} \
        --email !{ncbi_email}
    """
}

# Burkholderia pseudomallei automated Nextstrain build

This project is to keep a Nextstrain build for B. pseudomallei automatically updated whenever new data is made available in NCBI's RefSeq database.

The workflow expects that you have an API key for querying NCBI. To get a key, follow the instructions [here](https://support.nlm.nih.gov/knowledgebase/article/KA-05317/en-us).

It also requires you to specify an email address to be associated with your queries to NCBI.

To run a small example:
```
nextflow run \
    -profile docker \
    --api_key $NCBI_API_KEY \
    --ncbi_email $NCBI_EMAIL \
    main.nf
```

To run for B. pseudomallei, first download a reference genome as put it in `assets`.
Here I use [GCF_000756125.1](https://www.ncbi.nlm.nih.gov/assembly/GCF_000756125.1) as the reference.
```
nextflow run \
    -profile docker \
    --api_key $NCBI_API_KEY \
    --ncbi_email $NCBI_EMAIL \
    --ncbimeta_config ncbimeta/b_pseudomallei_refseq.yaml \
    --reference assets/GCF_000756125.1_ASM75612v1_genomic.fna \
    --output_folder burk_results \
    main.nf
```
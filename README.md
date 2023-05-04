# Burkholderia pseudomallei automated Nextstrain build

This project is to keep a Nextstrain build for B. pseudomallei automatically updated whenever new data is made available in NCBI's RefSeq database.

Run as:
```
nextflow run \
    -profile docker \
    --api_key $NCBI_API_KEY \
    --ncbi_email <email> \
    main.nf
```
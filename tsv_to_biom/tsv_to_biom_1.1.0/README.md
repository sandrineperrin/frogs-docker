### Converter tool frogs description ###

Converts a TSV file in BIOM file.

### Build the image ###

`docker build -t tsv_to_biom:1.1.0 .`

### tsv_to_biom example execution (help) ###

`docker run -it --rm -v <path_data>:/root tsv_to_biom:1.1.0 tsv_to_biom.py -b /root/example.tsv`

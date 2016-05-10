### Affiliation tools frogs description ###

Taxonomic affiliation of each OTU's seed by RDPtools and BLAST

### Build the image ###

`docker build -t affiliation_otu:0.10.0 .`

### Command example execution ###

`docker run -it --rm -v <path_data>:/root -w /root affiliation_otu:0.10.0 affiliation_OTU.py -h`


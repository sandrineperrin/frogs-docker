### Affiliation tools frogs description ###

Process some metrics on taxonomies.

### Build the image ###

`docker build -t affiliations_stat:1.2.0 .`

### Command example execution ###

`docker run -it --rm -v <path_data>:/root -w /root affiliations_stat:1.2.0 affiliations_stat.py -h`

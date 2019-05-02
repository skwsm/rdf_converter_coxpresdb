# RDF converter of the COEXPRESdb

## Usage

Usage: rdf_converter_coxpresdb [options]
  -f (mandatory) path to the ranking file
  -d (mandatory) path to the data directory 
  -i (optional) date issued (ex: 2019-02-25)
  -n (mandatory) dataset name (ex: Hsa-u.c2-0)

    ex) ruby rdf_converter_coexpresdb -f ranking.txt -d ./Hsa-u.v18-12.G26050-S164823.combat_pca_subagging.mrgeo.d -i "2019-02-25" -n "Hsa-u.c2-0" > output.ttl



## How to prepare the ranking file

Obtain a gene correlation table from https://coxpresdb.jp/download/, then unzip it. Move to the created directory and execute the following command.

    > find . -name "*" -type f | xargs -i ruby -e 'f = open(ARGV[0]); f.gets; g1 = File.basename(ARGV[0]); while line = f.gets do g2, mr = line.chomp.split; print "#{g1}\t#{line}" if g1 < g2 end' {} | sort -n -k 3 | nl > ../ranking.txt


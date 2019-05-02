#!/usr/bin/env ruby

require 'optparse'

class CoExpresDBRDF

  def initialize(params, threshold_total = 1.0, threshold_mr = 100)
    @gene_pairs = {}
    @params = params
    @file = @params["f"]
    @dir = @params["d"]
    @issued = params["i"]
    # the threhold value defined by the topside percentile. the default: 1 %
    @threshold_total = threshold_total 
    # the number of MR score ranking. default: 100
    @threshold_mr = threshold_mr
    @lines_total = 0
    @lines_topside_percentile = 0
    @data_within_topside_percentile = {}
    # count the number of lines of the ranking file
    open(@file) { |f| while f.gets; end; @lines_total = f.lineno }
    @lines_topside_percentile = (@lines_total * @threshold_total / 100 ).floor
  end

  def prefixes
    print "@prefix m2r: <http://med2rdf.org/ontology/med2rdf#> .\n"
    print "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n"
    print "@prefix dcterms: <http://purl.org/dc/terms/> .\n"
    print "@prefix obo: <http://purl.obolibrary.org/obo/> .\n"
    print "@prefix ncbigene: <http://identifiers.org/ncbigene/> .\n"
    print "@prefix sio: <http://semanticscience.org/resource/> .\n"
    print "@prefix coxpresdb: <https://coxpresdb.jp/dataset/> .\n"
    print "@prefix coxpresdbo: <https://coxpresdb.jp/ontology/> .\n"
    print "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n"
    print "\n"
  end

  def meta_information
    print "coxpresdb:#{@params['n']}\n" unless @params['n'] == nil
    print "  dcterms:identifier \"#{@params['n']}\" ;\n" unless @params['n'] == nil
    print "  dcterms:issued \"#{@params['i']}\"^^xsd:date .\n" unless @params['i'] == nil
    print "\n\n"
  end

  def set_data_within_topside_percentile
    cnt = 0
    open(@file) { |f|
      while line = f.gets
        line_no, gene1, gene2, mr_score = line.chomp.split("\t")
        if line_no.to_i < @lines_topside_percentile
          if @data_within_topside_percentile.key?(gene1)
            @data_within_topside_percentile[gene1.to_s][gene2.to_s] = [line_no.to_i, mr_score.to_f]
            cnt += 1
          else
            @data_within_topside_percentile[gene1.to_s] = {gene2.to_s => [line_no.to_i, mr_score.to_f]}
            cnt += 1
          end
        else
          break
        end
      end
    }
  end


  def to_rdf
    prefixes
    meta_information
    set_data_within_topside_percentile

    ranking = nil
    Dir.chdir(@dir)
    Dir.glob('*').each do |file|
      gene1 = File.basename(file)
      open(file) { |f|
        line_count = 0
        while line = f.gets
          if line_count < @threshold_mr
            gene2, mr_score = line.chomp.split("\t")
            key_gene1 = gene1 < gene2 ? gene1 : gene2
            key_gene2 = gene1 < gene2 ? gene2 : gene1
            if @data_within_topside_percentile.key?(key_gene1)
              if @data_within_topside_percentile[key_gene1].key?(key_gene2)
                ranking = @data_within_topside_percentile[key_gene1][key_gene2][0]
                @data_within_topside_percentile[key_gene1].delete(key_gene2)
              end
            end
            print "[]\n" 
            print "  coxpresdbo:gene ncbigene:#{gene1} ;\n" 
            print "  coxpresdbo:gene ncbigene:#{gene2} ;\n" 
            print "  coxpresdbo:mr_score #{mr_score} ;\n"
            print "  coxpresdbo:ranking #{ranking} ;\n" unless ranking == nil
            print "  coxpresdbo:dataset coxpresdb:#{@params["n"]} ;\n"
            print "  a coxpresdbo:CoExpressedGenePair .\n"
            print "\n"
          else
            break
          end 
          line_count += 1
          ranking = nil
        end
      }
    end
    @data_within_topside_percentile.each do |gene1, hash|
      if hash.size != 0
        hash.each do |gene2, ary|
          ranking = ary[0]
          mr_score = ary[1]
          print "[]\n"
          print "  coxpresdbo:gene ncbigene:#{gene1} ;\n"
          print "  coxpresdbo:gene ncbigene:#{gene2} ;\n"
          print "  coxpresdbo:mr_score #{mr_score} ;\n"
          print "  coxpresdbo:ranking #{ranking} ;\n" unless ranking == nil
          print "  coxpresdbo:dataset coxpresdb:#{@params["n"]} ;\n"
          print "  a coxpresdbo:CoExpressedGenePair .\n"
          print "\n"
        end
      end
    end
  end
end

def help
  print "Usage: mk_rdf_coxpresdb_by_total_mr [options]\n"
  print "  -f (mandatory) path to the ranking file\n"
  print "  -d (mandatory) path to the data directory \n"
  print "  -i (optional) date issued (ex: 2019-02-25)\n"
  print "  -n (mandatory) dataset name (ex: Hsa-u.c2-0)\n"
end

params = ARGV.getopts('f:d:i:n:')
if params["f"] == nil || params["d"] == nil || params["n"] == nil 
  help
  exit
end

coxpresdb = CoExpresDBRDF.new(params, 1, 100)
coxpresdb.to_rdf


# Can we run this or something like this?
# https://github.com/marcelm/cutadapt/issues/157
# https://www.biostars.org/p/123237/
# Some fastq files 
# wget ndr.md/data/bio/{R1.fastq.gz,R2.fastq.gz,ref.fa}

PW=$PASH_TOP/evaluation/scripts/input
cd $PW


#remove adapter
remove_adapter()
(
  find -name "*.fastq" |  sort | uniq | xargs -I {} cutadapt -a AGATCGGAAGAGCACAC {} >  /dev/null
)

# convert fastq to fasta format
# It recognizes the extension .fasta and it converts the input to tha format
convert_to_fasta()
(
  find . -name "*.fastq" | xargs -I {} cutadapt -o {}.fasta.gz {}
)
# remove more than once adapter, run the tool twice
# We could create random adapter inputs for several fastq
remove_adapter_twice()
(
  cutadapt -g ^TTAAGGCC -g ^AAGCTTA R1.fastq | cutadapt -a TACGGACT - > /dev/null
  cutadapt -g ^TTAAAACC -g ^AAGCTTA R1.fastq | cutadapt -a TACGAACT - > /dev/null
)

# trim primers
trim_primers()
(
  find . -name "*.fastq" | xargs -I {}  cutadapt -a TCCTCCGCTTATTGATAGC -o ${i}\_trimmed.fastq {}; 
)

# convert sam to bam
# Need INPUT HERE
sam_to_bam()
(

  find . -name "*.sam" | xargs -I {} sh -c 'samtools view -bS -q15 "$1" > \
  $1.bam; samtools sort "$1".bam -o "$1".sorted' sh {}
  #find . -name "*.bam" | xargs -I {} sh -c 'samtools sort "$1" -o   "$1".sorted' sh {}

  #find . -name "*.bam" | xargs -I {} samtools sort {}.bam {}
 # | samtools sort {}.bam {} " 
  #  for i in "${NAMES[@]}"
#  do
#    samtools view -bS -q15 $i.sam > $i.bam
#    samtools sort $i.bam $i
#  done 
)

# Here are sample steps to generate a single paired read from hg19:
# https://www.biostars.org/p/150010/
pipeline()
(
  #download hg19 reference genome, e.g.
  #wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.fai
  #wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz
  #gunzip human_g1k_v37.fasta.gz

  #filter out a single chromosome and index it, e.g.
  samtools faidx human_g1k_v37.fasta 20 > human_g1k_v37_chr20.fasta
  bowtie2-build human_g1k_v37_chr20.fasta homo_chr20
  #simulate a single read sample, e.g. here is for a single (-N 1) paired read:
  wgsim/wgsim -N 1 human_g1k_v37_chr20.fasta single.read1.fq single.read2.fq > wgsim.out
  #generate the sam, e.g.
  bowtie2 -x homo_chr20 -1 single.read1.fq -2 single.read2.fq -S single_pair.sam
  #generate a bam
  samtools view -b -S -o single_pair.bam single_pair.sam 
  #sort and index it
  samtools sort single_pair.bam -o single_pair.sorted.bam
  # this seems to not affect the file, but in other cases, its indeed needed
  samtools index single_pair.sorted.bam 
)

# https://dfzljdn9uc3pi.cloudfront.net/2013/203/1/Supplement_S2.pdf
# #Script to automatically process X number samples, produce a reference
# assembly, map reads back to the assembly, and call SNPs 
# https://zenodo.org/record/940733

#remove_adapter
#remove_adapter_twice
#convert_to_fasta
#trim_primers
#pipeline
sam_to_bam
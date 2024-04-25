#!/bin/bash -l

### TORQUE stuff here ####

### To send email when the job is completed:
#PBS -m ae
#PBS -M {email address}

# Tell Sun grid engine that this is a Bash script
#PBS -S /bin/bash
# Write errors to this file - make sure the directory exists
#PBS -e /path/to/error.txt

# Log output to this file - make sure the directory exists
#PBS -o /path/to/log.txt

#PBS -l walltime=48:00:00
#PBS -l nodes=1:ppn=32

# maximum amount of memory used by any single process
#PBS -l mem=250gb
# ALTERNATIVELY: -l mem=32gb # amount of physical memory used by the job

### Run in the queue named
### #PBS -q med4gb

# name of the job
#PBS -N {job_name}

#This came from Qiyun's code for Shogun gOTUs.
#PBS -V
#PBS -j oe
#PBS -d .

# BASH stuff here

cd /working/dir/

set -e
cpus=$PBS_NUM_PPN

export TMPDIR=/temp/path/
tmp=$(mktemp -d --tmpdir)
export TMPDIR=$tmp
trap "rm -r $tmp; unset TMPDIR" EXIT

# mkdir tmp
# tmp=tmp

# change aligners by arguing when submitting the job: qsub -v aligner=burst gOTU_bash.sh
aligner=${aligner:-bowtie2}
input=/path/to/sample_list.txt
db=/projects/genome_annotation/profiling/dbs/wol/shogun

shogun_env=shogun
utree_dir=/projects/genome_annotation/profiling/tools/shogun/UTree/2.0RF/linux64
burst_dir=/projects/genome_annotation/profiling/tools/shogun/BURST/0.99.7f
bowtie2_dir=/projects/genome_annotation/profiling/dbs/wol/shogun

source activate $shogun_env
export PATH=$utree_dir:$burst_dir:$bowtie2_dir:$PATH

declare -A a2ext=( [bowtie2]=sam [utree]=tsv [burst]=b6 )

cd $tmp
while IFS=$'\t' read -r id fwd rev
do
   echo $id
   seqtk mergepe $fwd $rev | seqtk seq -A > $id.fa
   shogun align -t $cpus -d $db -a $aligner -i $id.fa -o .
   rm $id.fa
   lext=$aligner.${a2ext[$aligner]}
   mv alignment.$lext $id.$lext
   shogun assign_taxonomy -d $db -a $aligner -i $id.$lext -o $id.profile.tsv
   for level in phylum genus species
   do
       shogun redistribute -d $db -l $level -i $id.profile.tsv -o $id.redist.$level.txt
   done
   shogun normalize -i $id.profile.tsv -o $id.profile.norm.tsv
   xz -T$cpus -9 $id.$lext
   mv $id.* $PBS_O_WORKDIR/
done < $input

source deactivate
source activate qiime2-2019.7

translation = /projects/genome_annotation/profiling/dbs/wol/nucl2g.txt
pythonFile = /projects/genome_annotation/profiling/scripts/gOTU_from_maps.py
outputPrefix = nextera_flex.gOTUs
filterPython = /projects/genome_annotation/profiling/scripts/filter_otus_per_sample.py

echo python $pythonFile $PBS_O_WORKDIR/ $outputPrefix -m $aligner -e ${a2ext[$aligner]}.xz -t $translation

python $pythonFile $PBS_O_WORKDIR/ $outputPrefix -m $aligner -e ${a2ext[$aligner]}.xz -t $translation

declare -a gotuTableTypes=(uniq norm all)
for tableType in "${gotuTableTypes[@]}"
do
  biom convert -i $outputPrefix_{$tableType}.tsv -o $outputPrefix_{$tableType}.biom --table-type="OTU table" --to-hdf5

  python $filterPython $outputPrefix_{$tableType}.biom 0.0001 $outputPrefix_{$tableType}.filt.biom

  qiime tools import \
  --input-path $outputPrefix_{$tableType}.filt.biom \
  --type 'FeatureTable[Frequency]' \
  --output-path $outputPrefix_{$tableType}.filt.qza
done

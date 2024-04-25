#!/bin/bash
#PBS -V
#PBS -l nodes=1:ppn=30
#PBS -l walltime=24:00:00
#PBS -l mem=240gb
#PBS -M {email address}
#PBS -m abe

module load samtools_1.3.1
module load bowtie2_bowtie2-2.3.2
module load bedtools_2.26.0

sample_list='/path/to/sample_list.txt'
input_path='/path/to/fastq_files/'
output_path='/output/path/'
temp_path='/temp/path/'
fwd_suffix='_R1_001_trimmed_paired.fastq.gz'
rev_suffix='_R2_001_trimmed_paired.fastq.gz'

for i in $(cat < "$sample_list");
do
    echo "Processing sample $i"
    
    seq_f="$input_path""$i""$fwd_suffix"
    seq_r="$input_path""$i""$rev_suffix"

    echo "Forward path: $seq_f"
    echo "Reverse path: $seq_r"
    
    filtered_sam="$i"_trimmed_paired_filtered_sam
    filtered_unsorted_bam="$i"_trimmed_paired_filtered_unsorted_bam
    filtered_bam="$i"_trimmed_paired_filtered_bam
    f_filtered_fastq="$i"_R1_001_trimmed_paired_filtered
    r_filtered_fastq="$i"_R2_001_trimmed_paired_filtered

    echo "Generating files:"
    echo "Output file: $filtered_unsorted_sam"
    echo "Output file: $filtered_sam"
    echo "Output file: $filtered_bam"
    echo "Output file: $f_filtered_fastq"
    echo "Output file: $r_filtered_fastq"

    bowtie2 \
      -p 30 \
      -x /databases/bowtie/mouse_reference/ \
      --very-sensitive \
      -1 "$input_path""$i""$fwd_suffix" \
      -2 "$input_path""$i""$rev_suffix" \
      2> "$temp_path"bowtie2_log_"$i".txt \
      -S "$temp_path""$filtered_sam".sam

    samtools view \
      -f 12 \
      -F 256 \
      -bS "$temp_path""$filtered_sam".sam \
      -o "$temp_path""$filtered_unsorted_bam".bam\
      2> "$temp_path"samtools_log.txt

    samtools sort \
      -T "$temp_path"/"$i" \
      -@ 30 \
      -n \
      -o "$temp_path""$filtered_bam".bam \
      "$temp_path""$filtered_unsorted_bam".bam \
      2> "$temp_path"samtools_log.txt

    bedtools bamtofastq \
      -i "$temp_path""$filtered_bam".bam \
      -fq "$output_path""$f_filtered_fastq".fastq \
      -fq2 "$output_path""$r_filtered_fastq".fastq \
      2> "$temp_path"bedtools_log.txt
done


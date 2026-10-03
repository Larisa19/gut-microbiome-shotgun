nextflow.enable.dsl=2

include { MULTIQC } from './modules/multiqc/main_multiqc.nf'
include { CUTADAPT; SUMMARY_CUTADAPT } from './modules/cutadapt/main_cutadapt'
include { FASTQC_TRIMMED } from './modules/fastqc_trimmed/main_fastqc_trimmed.nf'
include { MULTIQC_TRIMMED } from './modules/multiqc_trimmed/main_multiqc_trimmed.nf'

process FASTQC_RAW {

    tag "$sample"

    publishDir "${projectDir}/results/fastqc", mode: 'copy'

    input:
    tuple val(sample), path(read1), path(read2)

    output:
    tuple val(sample), path("*_fastqc.zip"), emit: fastqc_zip
    path "*_fastqc.html"

    script:
    """
    fastqc ${read1} ${read2}
    """
}


workflow {

    samples = channel
        .fromPath('data/raw/*_1.fastq.gz')
        .map { read1 ->

            def sample = read1.name.replaceFirst(/_1\.fastq\.gz$/, '')
            def read2 = file("data/raw/${sample}_2.fastq.gz")

            tuple(sample, read1, read2)
        }

    FASTQC_RAW(samples)

    fastqc_results = channel
        .fromPath('results/fastqc/*_fastqc.zip', checkIfExists: true)
        .collect()

    MULTIQC(fastqc_results)

    samples_cutadapt = channel
        .fromPath('data/raw/*_1.fastq.gz')
        .map { read1 ->
            def sample = read1.name.replaceFirst(/_1\.fastq\.gz$/, '')
            def read2 = file("data/raw/${sample}_2.fastq.gz")

            tuple(sample, read1, read2)
        }

    CUTADAPT(samples_cutadapt)

    SUMMARY_CUTADAPT(
        CUTADAPT.out.cutadapt_report.collect()
    )
    FASTQC_TRIMMED(
        CUTADAPT.out.trimmed_reads
    )

    trimmed_fastqc = FASTQC_TRIMMED.out.fastqc_zip
    .map { sample, zip -> zip }
    .collect()

    MULTIQC_TRIMMED(trimmed_fastqc)
}
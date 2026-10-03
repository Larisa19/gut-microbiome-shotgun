process MULTIQC {

    tag "Raw read QC"

    publishDir "${projectDir}/results/multiqc", mode: 'copy'

    input:
    path fastqc_results

    output:
    path "multiqc_report.html"

    script:
    """
    multiqc . \
        --force \
        --filename multiqc_report.html
    """
}

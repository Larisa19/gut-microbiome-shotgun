# Gut Microbiome Shotgun Metagenomics

Reproducible **shotgun metagenomics workflow** developed in **Nextflow DSL2** to investigate gut microbiome changes associated with a legume-enriched diet in a randomized controlled trial of adults with prediabetes.

The project is being developed incrementally, with each analysis step incorporated into the workflow and documented here. The main focus is on reproducible workflow development, biological reasoning and transparent documentation of analytical decisions.

---

## 1. Study background

This project uses publicly available data from the randomized controlled trial:

**A legume-enriched diet improves metabolic health in prediabetes mediated through gut microbiome: a randomized controlled trial**

* **NCBI BioProject:** `PRJNA1201249`
* **Study population:** adults with prediabetes
* **Intervention:** legume-enriched diet
* **Sample type:** fecal microbiome
* **Sequencing:** shotgun metagenomic sequencing
* **Platform:** Illumina NovaSeq 6000
* **Study duration:** 16 weeks
* **Sampling:** W0, W2, W4, W8, W12 and W16

The published study investigated changes in the gut microbiome together with metabolic and other biological measurements.

For this portfolio project, a smaller **paired longitudinal subset** was selected to develop and demonstrate a reproducible shotgun metagenomics workflow. The selected samples represent two participants with measurements at baseline (W0) and week 16 (W16).

---

## 2. Biological question

> **How does the gut microbiome change between baseline and week 16 in participants undergoing different dietary interventions in this randomized controlled trial?**

The analysis focuses on paired samples from the same participants at W0 and W16. This provides a simple longitudinal framework for exploring changes in microbial composition and function while keeping the participant as the reference unit.

The project is intended as a **portfolio-scale reproducible analysis**, rather than a complete reanalysis of the original clinical trial.

---

## 3. Samples

| Sample     | Participant | Group  | Timepoint | SRA run     |
| ---------- | ----------- | ------ | --------- | ----------- |
| FBI029_W0  | FBI029      | Group1 | W0        | SRR31800610 |
| FBI029_W16 | FBI029      | Group1 | W16       | SRR31800159 |
| FBI052_W0  | FBI052      | Group2 | W0        | SRR31800271 |
| FBI052_W16 | FBI052      | Group2 | W16       | SRR31800323 |

Metadata:

```text
samplesheet/samples.tsv
```

The complete sample metadata used during project preparation are stored in:

```text
samplesheet/shotgun_metadata.tsv
```

---

## 4. Analysis workflow

The workflow is being developed incrementally. The current planned analysis is:

```text
Raw paired-end FASTQ
        │
        ▼
      FastQC
        │
        ▼
      MultiQC
        │
        ▼
     Cutadapt
        │
        ▼
 Trimmed FASTQ
        │
        ├── FastQC
        │
        └── MultiQC
                │
                ▼
            MetaPhlAn
                │
                ▼
        Taxonomic profiling
                │
                ▼
             HUMAnN
                │
                ▼
       Functional profiling
                │
                ▼
       Downstream analysis
```

Each stage is implemented as a reproducible Nextflow component and added to the workflow as the analysis progresses.

Step-by-step analysis

Step 1 — Raw read quality control

Input: Raw paired-end shotgun metagenomic FASTQ files

The raw sequencing reads were assessed before preprocessing to evaluate sequencing quality and identify potential issues.

Tool: FastQC

FastQC was run automatically through Nextflow for all four selected biological samples, generating reports for both R1 and R2.

Output: FastQC reports

Files: results/fastqc/

Step 2 — Quality control - MultiQC

The individual FastQC reports were aggregated with MultiQC to provide a global overview of raw-read quality across the dataset.

MultiQC was implemented as a reusable Nextflow module and uses the existing FastQC .zip reports as input.

Output: results/multiqc/multiqc_report.html

## 3. Adapter identification

Before adapter trimming, the adapter sequences were identified from the sequencing data rather than assumed from the sequencing platform alone.

The study used paired-end Illumina NovaSeq 6000 sequencing. FastQC detected low-level adapter contamination in the raw reads. To investigate the adapter sequences, the expected Illumina adapter sequences were searched directly in the FASTQ files.

The following sequences were detected in the selected sample (`FBI029_W0`):

| Read | Adapter sequence                    | Matches |
| ---- | ----------------------------------- | ------: |
| R1   | `AGATCGGAAGAGCACACGTCTGAACTCCAGTCA` |   7,477 |
| R2   | `AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT` |   7,532 |

The presence of these sequences in both reads supports their use as the adapter sequences for the paired-end trimming step with Cutadapt.

This provides a data-supported basis for the adapter configuration used in the next workflow step.

### 4. Adapter trimming

The identified adapter sequences were removed from the paired-end reads using Cutadapt.
Cutadapt was implemented as a reusable Nextflow module and processes all samples automatically.
A JSON report was generated for each sample to retain the trimming statistics.

Input: file_1.fastq.gz file_2.fastq.gz
Output: results/trimmed/

A summary table was generated automatically from the Cutadapt reports:
Output: results/trimmed/cutadapt_summary.tsv

The trimming step was completed successfully for all four paired-end samples. Adapter sequences were detected in approximately 2.4–2.8% of reads, while the majority of reads did not contain detectable adapter sequence.

| Sample     | Input reads | R1 adapter reads (%) | R2 adapter reads (%) |
| ---------- | ----------: | -------------------: | -------------------: |
| FBI029_W0  |  24,354,291 |      596,811 (2.45%) |      583,191 (2.39%) |
| FBI029_W16 |  23,684,666 |      667,974 (2.82%) |      645,015 (2.72%) |
| FBI052_W0  |  24,538,509 |      618,875 (2.52%) |      617,119 (2.51%) |
| FBI052_W16 |  24,342,011 |      594,267 (2.44%) |      584,064 (2.40%) |


## 5. Quality control after trimming

FastQC was run again on the trimmed reads to assess read quality after adapter removal.
The FastQC results were aggregated with MultiQC to provide a global overview of the processed reads.

Both steps were implemented as reusable Nextflow modules.

Output: results/fastqc_trimmed/

Output: results/multiqc_trimmed/multiqc_report.html

The post-trimming QC was used to verify that the processed reads were suitable for downstream taxonomic profiling.



process MERGE_MAPPED_BAMS {

    label "MERGE_MAPPED_BAMS_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleDirectory", mode:  'link', pattern: "*.merged.sorted.bam", saveAs: {s-> "${params.sampleId}.${params.sequencingTarget}.bam"}
    publishDir "$params.sampleDirectory", mode:  'link', pattern: "*.merged.sorted.bam.bai", saveAs: {s-> "${params.sampleId}.${params.sequencingTarget}.bam.bai"}

    input:
        path bamList

    output:
        path "*.merged.sorted.bam",  emit: merged_sorted_bam
        path "*.merged.sorted.bam.bai",  emit: bai
        path "versions.yaml", emit: versions

    script:

        """
        samtools \
            merge \
            --threads $task.cpus \
            $bamList \
            -o ${params.sampleId}.merged.sorted.bam

        samtools \
            index \
            -@ $task.cpus \
            ${params.sampleId}.merged.sorted.bam

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS

        """

}

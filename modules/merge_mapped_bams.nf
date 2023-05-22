
process MERGE_MAPPED_BAMS {

    label "MERGE_MAPPED_BAMS_${params.sampleId}_${params.userId}"

    Boolean isOnt = params.sequencingPlatform.equalsIgnoreCase("ont")

    publishDir "$params.sampleDirectory", mode:  'link', pattern: "*.merged.sorted.bam", saveAs: {s-> "${params.sampleId}.${params.sequencingTarget}.bam"}, enabled: isOnt
    publishDir "$params.sampleDirectory", mode:  'link', pattern: "*.merged.sorted.bam.bai", saveAs: {s-> "${params.sampleId}.${params.sequencingTarget}.bam.bai"}, enabled: isOnt
    publishDir "$params.sampleDirectory", mode:  'link', pattern: "*.merged.sorted.bam.md5sum", saveAs: {s-> "${params.sampleId}.${params.sequencingTarget}.bam.md5sum"}, enabled: isOnt

    input:
        path bamList

    output:
        path "*.merged.sorted.bam",  emit: merged_sorted_bam
        path "*.merged.sorted.bam.bai",  emit: bai, optional: true
        path "*.merged.sorted.bam.md5sum",  emit: md5sum, optional: true
        path "versions.yaml", emit: versions

    script:
        def numCPUs = Integer.valueOf("$task.cpus")
        def merge_threads = Math.max(1, Math.ceil((numCPUs/2) - 1).intValue())
        def sort_threads = Math.max(1, Math.floor(numCPUs/2).intValue())

        """
        samtools \
            merge \
            --threads $merge_threads \
            $bamList \
            -o - \
        | \
        samtools \
            sort \
            -@ $sort_threads \
            -m 1G \
            - \
            -o ${params.sampleId}.merged.sorted.bam

        if [ $isOnt ] ; then
            samtools \
                index \
                -@ $task.cpus \
                ${params.sampleId}.merged.sorted.bam

            md5sum ${params.sampleId}.merged.sorted.bam | awk '{print \$1}' > ${params.sampleId}.merged.sorted.bam.md5sum
        fi

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS

        """

}

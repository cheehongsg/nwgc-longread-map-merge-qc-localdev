process MERGE_MAPPED_BAMS {

    label "MERGE_MAPPED_BAMS_${params.sampleId}_${params.userId}"

    input:
        path bamList

    output:
        path "*.merged.sorted.bam",  emit: merged_sorted_bam
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
            -m $task.memory \
            - \
            -o ${params.sampleId}.merged.sorted.bam

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS

        """

}

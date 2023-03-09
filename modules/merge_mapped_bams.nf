process MERGE_MAPPED_BAMS {

    label "MERGE_MAPPED_BAMS_${params.sampleId}_${params.userId}"

    debug true
    module "$params.initModules"
    module "$params.samtoolsModule"
    memory "$params.mergeMappedBams_memory"
    clusterOptions "$params.defaultClusterOptions -pe serial $params.mergeMappedBams_numCPUs -l d_rt=1:0:0"

    input:
        path bamList

    output:
        path "*.merged.sorted.bam",  emit: merged_sorted_bam
        path "versions.yaml", emit: versions

    script:
        """
        samtools \
            merge \
            --threads 9 \
            $bamList \
            -o - \
        | \
        samtools \
            sort \
            -@ 10 \
            -m $params.mergeMappedBams_memory \
            - \
            -o ${params.sampleId}.merged.sorted.bam

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS

        """

}

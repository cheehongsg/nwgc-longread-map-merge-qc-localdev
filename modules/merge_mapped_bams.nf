process MERGE_MAPPED_BAMS {

    label "${params.userId}_MERGE_MAPPED_BAMS_${params.sampleId}"

    debug true
    module "$params.initModules"
    module "$params.samtoolsModule"
    memory "$params.mergeMappedBams.memory"
    clusterOptions "$params.defaultClusterOptions -l d_rt=1:0:0"

    input:
        path bamList

    output:
        path "*.merged.sorted.bam",  emit: merged_sorted_bam

    script:
        """
        samtools \
            merge \
            $bamList \
            -o - \
        | \
        samtools \
            sort \
            - \
            -o ${params.sampleId}.merged.sorted.bam
        """

}

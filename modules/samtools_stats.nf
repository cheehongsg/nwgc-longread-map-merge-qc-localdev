process SAMTOOLS_STATS {

    label "SAMTOOLS_STATS_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleQCDirectory", mode: 'link'
 
    debug true
    module "$params.initModules"
    module "$params.samtoolsModule"
    memory "$params.samtoolsStats.memory"
    clusterOptions "$params.defaultClusterOptions -l d_rt=1:0:0"

    input:
        path bam

    output:
        path "*.stats.txt"

    script:
        """
        mkdir -p $params.sampleQCDirectory

        samtools \
            stats \
            $bam \
            > ${params.sampleId}.samtools.stats.txt \
        """

}

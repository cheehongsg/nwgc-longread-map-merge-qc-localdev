process SAMTOOLS_STATS {

    label "SAMTOOLS_STATS_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleQCDirectory", mode: 'link', pattern: '*.stats.txt'
 
    debug true
    module "$params.initModules"
    module "$params.samtoolsModule"
    memory "$params.samtoolsStats_memory"
    clusterOptions "$params.defaultClusterOptions -pe serial $params.samtoolsStats_numCPUs -l d_rt=1:0:0"

    input:
        path bam
        path bai

    output:
        path "*.stats.txt"
        path "versions.yaml", emit: versions

    script:
        """
        mkdir -p $params.sampleQCDirectory

        samtools \
            stats \
            $bam \
            --threads $params.samtoolsStats_numCPUs \
            > ${params.sampleId}.samtools.stats.txt \

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS

        """

}

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
        path "versions.yaml", emit: versions

    script:
        """
        mkdir -p $params.sampleQCDirectory

        samtools \
            stats \
            $bam \
            > ${params.sampleId}.samtools.stats.txt \

        cat <<-END_VERSIONS > versions.yaml
        ${task.process}:
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS

        """

}

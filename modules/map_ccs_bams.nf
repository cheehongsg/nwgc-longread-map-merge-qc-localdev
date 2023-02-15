process MAP_CCS_BAMS {

    label "MAP_CCS_BAMS_${params.sampleId}_${params.userId}"

    debug true
    module "$params.initModules"
    module "$params.smrttoolsModule"
    memory "$params.mapCCSBams.memory"
    clusterOptions "$params.defaultClusterOptions -pe serial $params.mapCCSBams.numCPUs -l d_rt=1:0:0"

    input:
        path ccsBam

    output:
        path "*.mapped.bam",  emit: mapped_bam
        path "versions.yaml", emit: versions

    script:
        """
        pbmm2 \\
            align \\
            --num-threads $params.mapCCSBams.numCPUs \\
            --unmapped \\
            $params.referenceGenome \\
            $ccsBam \\
            ${ccsBam}.mapped.bam

        cat <<-END_VERSIONS > versions.yaml
        "${task.process}":
            pbmm2: \$(pbmm2 --version | awk '{print \$2}')
        END_VERSIONS
        """

}

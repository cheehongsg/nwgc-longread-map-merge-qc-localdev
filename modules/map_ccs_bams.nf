process MAP_CCS_BAMS {

    label "${params.userId}_MAP_CCS_BAMS_${params.sampleId}"

    debug true
    module "$params.initModules"
    module "$params.smrttoolsModule"
    memory "$params.mapCCSBams.memory"
    clusterOptions "$params.defaultClusterOptions -pe serial $params.mapCCSBams.numCPUs -l d_rt=1:0:0"

    input:
        path ccsBam

    output:
        path "*.mapped.bam",  emit: mapped_bam

    script:
        """
        pbmm2 \\
            align \\
            --num-threads $params.mapCCSBams.numCPUs \\
            --unmapped \\
            $params.referenceGenome \\
            $ccsBam \\
            ${ccsBam}.mapped.bam
        """

}

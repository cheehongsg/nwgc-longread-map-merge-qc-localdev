process PICARD_COVERAGE_METRICS {

    publishDir "$params.sampleQCDirectory"
 
    debug true
    module "$params.initModules"
    module "$params.picardModule"
    memory "$params.picardCoverageMetrics.memory"
    clusterOptions "$params.defaultClusterOptions -l d_rt=1:0:0"

    input:
        path bam

    output:
        path "*.picard.coverage.*"

    script:
        """
        mkdir -p $params.sampleQCDirectory

        java -xmx${params.picardCoverageMetrics.memory} \
            -jar \$PICARD_DIR/picard.jar CollectRawWgsMetrics \
            --INPUT $bam \
            --COUNT_UNPAIRED true \
            --READ_LENGTH 17000 \
            --INCLUDE_BQ_HISTOGRAM \
            --REFERENCE_SEQUENCE $params.referenceGenome \
            --VALIDATION_STRINGENCY LENIENT \
            --OUTPUT ${params.sampleId}.picard.coverage
        """

}

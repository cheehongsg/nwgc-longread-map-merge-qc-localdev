process PICARD_QUALITY_METRICS {

    publishDir "$params.sampleQCDirectory"
 
    debug true
    module "$params.initModules"
    module "$params.picardModule"
    memory "$params.picardQualityMetrics.memory"
    clusterOptions "$params.defaultClusterOptions -l d_rt=1:0:0"

    input:
        path bam

    output:
        path "*.picard.quality.*"

    script:
        """
        mkdir -p $params.sampleQCDirectory

        java -xmx${params.picardQualityMetrics.memory} \
            -jar \$PICARD_DIR/picard.jar CollectQualityYieldMetrics \
            --INPUT $bam \
            --VALIDATION_STRINGENCY LENIENT \
            --OUTPUT ${params.sampleId}.picard.quality
        """

}

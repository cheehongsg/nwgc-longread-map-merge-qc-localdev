process PICARD_QUALITY_METRICS {

    label "PICARD_QUALITY_METRICS_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleQCDirectory", mode: 'link', pattern: '*.picard.quality.txt'
 
    input:
        path bam
        path bai

    output:
        path "*.picard.quality.txt"
        path "versions.yaml",  emit: versions

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1)

        """
        mkdir -p $params.sampleQCDirectory

        java -Xmx$javaMemory \
            -jar \$PICARD_DIR/picard.jar CollectQualityYieldMetrics \
            --INPUT $bam \
            --VALIDATION_STRINGENCY LENIENT \
            --OUTPUT ${params.sampleId}.picard.quality.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            java: \$(java -version 2>&1 | grep version | awk '{print \$3}' | tr -d '"''')
            picard: \$(java -jar \$PICARD_DIR/picard.jar CollectRawWgsMetrics --version 2>&1 | awk '{split(\$0,a,":"); print a[2]}')
        END_VERSIONS

        """

}

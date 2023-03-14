process ADD_NM_TAGS {

    label "ADD_NM_TAGS_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleDirectory", mode:  'link', pattern: '*.nmtagged.bam'
    publishDir "$params.sampleDirectory", mode:  'link', pattern: '*.nmtagged.bam.bai'
 
    debug true
    module "$params.initModules"
    module "$params.samtoolsModule"
    memory "$params.addNMTags_memory"
    clusterOptions "$params.defaultClusterOptions -pe serial $params.addNMTags_numCPUs -l d_rt=1:0:0"

    input:
        path inputBam

    output:
        path "${params.sampleId}.${params.sequencingTarget}.bam", emit: bam
        path "${params.sampleId}.${params.sequencingTarget}.bam.bai", emit: index
        path "${params.sampleId}.${params.sequencingTarget}.bam.md5sum", emit: md5sum
        path "versions.yaml", emit: versions

    script:
        def outputBam = "$params.sampleId" + "." + "$params.sequencingTarget" + ".bam"

        """
        samtools \
            calmd \
            -b \
            --threads $params.addNMTags_numCPUs \
            $bam \
            $params.referenceGenome \
            > $outputBam \
        
        samtools \
            index \
            -@ $params.addNMTags_numCPUs \
            $outputBam

        md5sum $outputBam | awk '{print \$1}' > $outputBam.md5sum

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS

        """

}

process ADD_NM_TAGS {

    label "ADD_NM_TAGS_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleDirectory", mode:  'link', pattern: '*.nmtagged.bam'
    publishDir "$params.sampleDirectory", mode:  'link', pattern: '*.nmtagged.bam.bai'
 
    debug true
    module "$params.initModules"
    module "$params.samtoolsModule"
    memory "$params.addNMTags.memory"
    clusterOptions "$params.defaultClusterOptions -pe serial $params.addNMTags.numCPUs -l d_rt=1:0:0"

    input:
        path bam

    output:
        path "*.nmtagged.bam",  emit: nmtagged_bam
        path "*.nmtagged.bam.bai",  emit: index
        path "versions.yaml", emit: versions

    script:
        """
        samtools \
            calmd \
            -b \
            --threads $params.addNMTags.numCPUs \
            $bam \
            $params.referenceGenome \
            > ${params.sampleId}.merged.sorted.nmtagged.bam \
        
        samtools \
            index \
            ${params.sampleId}.merged.sorted.nmtagged.bam

        cat <<-END_VERSIONS > versions.yaml
        ${task.process}:
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS

        """

}

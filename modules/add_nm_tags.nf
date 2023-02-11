process ADD_NM_TAGS {

    label "${params.userId}_ADD_NM_TAGS_${params.sampleId}"

    publishDir "$params.sampleDirectory" mode:  'link'
 
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
        """

}

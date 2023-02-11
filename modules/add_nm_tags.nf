process ADD_NM_TAGS {

    publishDir "$params.sampleDirectory"
 
    debug true
    module "$params.initModules"
    module "$params.samtoolsModule"
    memory "$params.addNMTags.memory"
    clusterOptions "$params.defaultClusterOptions -pe serial $params.addNMTags.numCPUs -l d_rt=1:0:0"

    input:
        path bam

    output:
        path "*.nmtagged.bam",  emit: nmtagged_bam
        path "*.nmtagged.bai",  emit: index

    script:
        """
        samtools \
            calmd \
            -b \
            --threads $params.addNMTags.numCPUs \
            $bam \
            > ${params.sampleId}.merged.sorted.nmtagged.bam \
        
        samtools \
            index \
            ${params.sampleId}.merged.sorted.nmtagged.bam
        """

}

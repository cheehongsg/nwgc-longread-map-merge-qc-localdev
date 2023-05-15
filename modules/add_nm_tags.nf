process ADD_NM_TAGS {

    label "ADD_NM_TAGS_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleDirectory", mode:  'link', pattern: "${params.sampleId}.${params.sequencingTarget}.bam"
    publishDir "$params.sampleDirectory", mode:  'link', pattern: "${params.sampleId}.${params.sequencingTarget}.bam.bai"
    publishDir "$params.sampleDirectory", mode:  'link', pattern: "${params.sampleId}.${params.sequencingTarget}.bam.md5sum"
 
    input:
        path inputBam

    output:
        path "${params.sampleId}.${params.sequencingTarget}.bam", emit: bam
        path "${params.sampleId}.${params.sequencingTarget}.bam.bai", emit: bai
        path "${params.sampleId}.${params.sequencingTarget}.bam.md5sum", emit: md5sum
        path "versions.yaml", emit: versions

    script:
        def outputBam = "$params.sampleId" + "." + "$params.sequencingTarget" + ".bam"

        """
        samtools \
            calmd \
            -b \
            --threads $task.cpus \
            $inputBam \
            $params.referenceGenome \
            > $outputBam
        
        samtools \
            index \
            -@ $task.cpus \
            $outputBam

        md5sum $outputBam | awk '{print \$1}' > ${outputBam}.md5sum

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS

        """

}

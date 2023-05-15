process MAP_HIFI_BAMS {

    label "MAP_HIFI_BAMS_${params.sampleId}_${params.userId}"

    input:
        path hiFiBam

    output:
        path "*.mapped.bam",  emit: mapped_bam
        path "versions.yaml", emit: versions

    script:
        """
        pbmm2 \\
            align \\
            --num-threads $task.cpus \\
            --unmapped \\
            $params.referenceGenome \\
            $hiFiBam \\
            ${hiFiBam}.mapped.bam

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}_${task.index}':
            pbmm2: \$(pbmm2 --version | awk '{print \$2}')
        END_VERSIONS
        """

}

process MAP_ONT_BAM {

    label "MAP_ONT_BAM_${params.sampleId}_${params.userId}"

    input:
        path bam

    output:
        path "*.mapped.bam",  emit: mapped_bam
        path "versions.yaml", emit: versions

    script:
        """
        samtools \\
            fastq \\
            -T '*' \\
            -@ 3 \\
            $bam \\
        | \\
        minimap2 \\
            -a \\
            -x map-ont \\
            -t ${task.cpus} \\
            --MD \\
            -y \\
            $params.referenceGenome \\
            - \\
        | \\
        samtools \\
            sort \\
            - \\
            -@ 3 -m 1G \\
            -o ${bam}.mapped.bam

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}_${task.index}':
            minimap2: \$(minimap2 --version)
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS
        """

}

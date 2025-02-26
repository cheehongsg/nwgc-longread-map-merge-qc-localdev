process STRIP_KINETICS {

    label "STRIP_KINETICS_${params.sampleId}_${params.userId}"

    input:
        path bam

    output:
        path "*.primrose.bam",  emit: bam
        path "*.primrose.bam.bai",  emit: bai
        path "versions.yaml", emit: versions

    script:
        """
        PRIMROSE_WAS_RUN=true
        if ! samtools view -H $bam | grep ^@PG | grep -q ID:primrose ; then PRIMROSE_WAS_RUN=false; fi

        PRIMROSE_KEPT_KINETECS=false
        if samtools view -H $bam | grep ^@PG | grep ID:primrose | grep -q keep-kinetics; then PRIMROSE_KEPT_KINETECS=true; fi

        if [[ "\$PRIMROSE_WAS_RUN" = false || "\$PRIMROSE_KEPT_KINETECS" = true ]] ; then
            primrose \
                -j $task.cpus \
                $bam \
                ${bam}.primrose.bam;
        else
                ln $bam ${bam}.primrose.bam;
        fi

        samtools \
            index \
            -@ $task.cpus \
            ${bam}.primrose.bam

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}_${task.index}':
            primrose: \$(primrose --version | grep ^primrose | awk '{print \$2}')
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS
        """

}

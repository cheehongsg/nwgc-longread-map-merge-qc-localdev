process CONTAMINATION_CHECK {

    label "CONTAMINATION_CHECK_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleQCDirectory", mode: 'link'
 
    debug true
    module "$params.initModules"
    module "$params.samtoolsModule"
    module "$params.htslibModule"
    module "$params.verifyBamIdModule"
    memory "$params.contaminationCheck.memory"
    clusterOptions "$params.defaultClusterOptions -l d_rt=1:0:0"

    input:
        path bam

    output:
        path "*.VerifyBamID.selfSM"
        path "versions.yaml", emit: versions

    script:
        """
        mkdir -p $params.sampleQCDirectory

        VERIFYBAMID_RESOURCE=\$MOD_GSVERIFYBAMID_DIR/resource

        UDPATH=\$VERIFYBAMID_RESOURCE/1000g.phase3.100k.b38.vcf.gz.dat.UD
        BEDPATH=\$VERIFYBAMID_RESOURCE/1000g.phase3.100k.b38.vcf.gz.dat.bed
        MEANPATH=\$VERIFYBAMID_RESOURCE/1000g.phase3.100k.b38.vcf.gz.dat.mu

        samtools \
            mpileup \
            -B \
            -l \
            \$BEDPATH \
            $bam \
            -o ${params.sampleId}.pileup

        VerifyBamID \
            --PileupFile ${params.sampleId}.pileup \
            --UDPath \$UDPATH \
            --BedPath \$BEDPATH \
            --MeanPath \$MEANPATH \
            --Reference $params.referenceGenome \
            --Verbose \
            ${params.verifyBamId.additionalParameters} \
            --Output ${params.sampleId}.VerifyBamId

        cat <<-END_VERSIONS > versions.yaml
        ${task.process}:
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
            VerifyBamId: \$(module list 2>&1 | awk '{for (i=1;i<=NF;i++){if (\$i ~/^VerifyBamID/) {print \$i}}}' | awk -F/ '{print \$NF}')
        END_VERSIONS

        """

}

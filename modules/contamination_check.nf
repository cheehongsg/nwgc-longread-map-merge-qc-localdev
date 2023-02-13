process CONTAMINATION_CHECK {

    label "CONTAMINATION_CHECK_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleQCDirectory", mode: 'link'
 
    debug true
    module "$params.initModules"
    module "$params.samtoolsModule"
    memory "$params.contaminationCheck.memory"
    clusterOptions "$params.defaultClusterOptions -l d_rt=1:0:0"

    input:
        path bam

    output:
        path "*.VerifyBamID.selfSM"

    script:
        """
        mkdir -p $params.sampleQCDirectory

        VERIFYBAMID_RESOURCE=\$MOD_GSVERIFYBAMID_DIR/resource

        UDPATH=\$VERIFYBAMID_RESOURCE/1000g.phase3.100k.b38.vcf.gz.dat.UD
        BEDPATH=\$VERIFYBAMID_RESOURCE/1000g.phase3.100k.b38.vcf.gz.dat.bed
        MEANPATH=\$VERIFYBAMID_RESOURCE/1000g.phase3.100k.b38.vcf.gz.dat.mu

        time samtools \
                mpileup \
                -B \
                -l \
                \$BEDPATH \
                $bam \
                -o ${params.sampleId}.pileup

        time VerifyBamID \
                --PileupFile ${params.sampleId}.pileup \
                --UDPath \$UDPATH \
                --BedPath \$BEDPATH \
                --MeanPath \$MEANPATH \
                --Reference $params.referenceGenome \
                --Verbose true \
                --Output ${params.sampleId}.VerifyBamId

        """

}

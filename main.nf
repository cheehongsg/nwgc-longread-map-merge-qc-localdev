include { PACBIO_MAP_MERGE } from './workflows/pacbio-map-merge.nf'
include { ONT_MAP_MERGE_FASTQS } from './workflows/ont-map-merge-fastqs.nf'
include { ONT_MAP_MERGE_BAMS } from './workflows/ont-map-merge-bams.nf'
include { LONGREAD_QC } from './workflows/qc.nf'

workflow {
    NwgcCore.init(params)

    // Map-Merge
    if (params.mergedBam == null) {
        if (params.sequencingPlatform.equalsIgnoreCase("PacBio")) {
            PACBIO_MAP_MERGE()
            LONGREAD_QC(PACBIO_MAP_MERGE.out.bam, PACBIO_MAP_MERGE.out.bai)
        }
        else if (params.sequencingPlatform.equalsIgnoreCase("ONT")) {
            if (params.ontFastqFolders !=  null) {
                ONT_MAP_MERGE_FASTQS()
                LONGREAD_QC(ONT_MAP_MERGE_FASTQS.out.bam, ONT_MAP_MERGE_FASTQS.out.bai)
            }
            else {
                ONT_MAP_MERGE_BAMS()
                LONGREAD_QC(ONT_MAP_MERGE_BAMS.out.bam, ONT_MAP_MERGE_BAMS.out.bai)
            }
        }
        else {
            error "Error:  Unknown sequencingPlatform: ${params.sequencingPlatform}."
        }
    }
    else {
        LONGREAD_QC(params.mergedBam, "${params.mergedBam}.bai")
    }
}

workflow.onError {
    NwgcCore.error(workflow, "$params.sampleId")
}

workflow.onComplete {
    NwgcCore.processComplete(workflow, "$params.sampleId")
}

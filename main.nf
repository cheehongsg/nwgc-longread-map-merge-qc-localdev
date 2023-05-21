include { PACBIO_MAP_MERGE } from './workflows/pacbio-map-merge.nf'
include { ONT_MAP_MERGE } from './workflows/ont-map-merge.nf'
include { LONGREAD_QC } from './workflows/qc.nf'

workflow {

    // Map-Merge
    if (params.mergedBam == null) {
        if (params.sequencingPlatform.equalsIgnoreCase("PacBio")) {
            PACBIO_MAP_MERGE()
            LONGREAD_QC(PACBIO_MAP_MERGE.out.bam, PACBIO_MAP_MERGE.out.bai)
        }
        else if (params.sequencingPlatform.equalsIgnoreCase("ONT")) {
            ONT_MAP_MERGE()
            LONGREAD_QC(ONT_MAP_MERGE.out.bam, ONT_MAP_MERGE.out.bai)
        }
        else {
            error "Error:  Unknown sequencingPlatform: ${params.sequencingPlatform}."
        }
    }
    else {
        LONGREAD_QC(params.mergedBam, "${params.mergedBam}.bai")
    }

}

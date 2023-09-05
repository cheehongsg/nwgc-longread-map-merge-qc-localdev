include { ONT_MAP_MERGE_FASTQS } from '../workflows/ont-map-merge-fastqs.nf'
include { ONT_MAP_MERGE_BAMS } from '../workflows/ont-map-merge-bams.nf'

workflow ONT_MAP_MERGE {

    main:
        if (params.ontFastqFolders !=  null) {
            ONT_MAP_MERGE_FASTQS()
        }
        else {
            ONT_MAP_MERGE_BAMS()
        }

}
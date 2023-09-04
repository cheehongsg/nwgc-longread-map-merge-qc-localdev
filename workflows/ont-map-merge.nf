include { ONT_MAP_MERGE_FASTQS } from '../workflows/ont_map_merge_fastqs.nf'
include { ONT_MAP_MERGE_BAMS } from '.../workflows/ont_map_merge_bams.nf'

workflow ONT_MAP_MERGE {

    main:
        if (params.ontFastqFolders !=  null) {
            ONT_MAP_MERGE_FASTQS()
        }
        else {
            ONT_MAP_MERGE_BAMS()
        }

}
include { STRIP_KINETICS } from '../modules/strip_kinetics.nf'
include { MAP_HIFI_BAM } from '../modules/map_hifi_bam.nf'
include { MERGE_MAPPED_BAMS } from '../modules/merge_mapped_bams.nf'
include { ADD_NM_TAGS } from '../modules/add_nm_tags.nf'

workflow PACBIO_MAP_MERGE {

    main:
        def hiFiBams = Channel.fromPath(params.hiFiBams)

        // Map
        if (params.stripKinetics) {
            STRIP_KINETICS(hiFiBams)
            MAP_HIFI_BAM(STRIP_KINETICS.out.bam)
        }
        else {
            MAP_HIFI_BAM(hiFiBams)
        }

        // Merge
        MERGE_MAPPED_BAMS(MAP_HIFI_BAM.out.mapped_bam.collect())

        // NM TAGS
        ADD_NM_TAGS(MERGE_MAPPED_BAMS.out.merged_sorted_bam)

        // Versions
        ch_versions = Channel.empty()
        ch_versions = ch_versions.mix(MAP_HIFI_BAM.out.versions)
        ch_versions = ch_versions.mix(MERGE_MAPPED_BAMS.out.versions)
        ch_versions = ch_versions.mix(ADD_NM_TAGS.out.versions)
        ch_versions.unique().collectFile(name: 'map_merge_software_versions.yaml', storeDir: "${params.sampleDirectory}")

    emit:
        bam = ADD_NM_TAGS.out.bam
        bai = ADD_NM_TAGS.out.bai
        bam_md5sum =  ADD_NM_TAGS.out.md5sum
}
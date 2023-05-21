include { MAP_ONT_FASTQ } from '../modules/map_ont_fastq.nf'
include { MERGE_MAPPED_BAMS } from '../modules/merge_mapped_bams.nf'
include { ADD_NM_TAGS } from '../modules/add_nm_tags.nf'

workflow ONT_MAP_MERGE {

    main:
        def ontFastqs = Channel.fromPath(params.ontFastqs)
        MAP_ONT_FASTQ(ontFastqs)

        // Merge
        MERGE_MAPPED_BAMS(MAP_ONT_FASTQ.out.mapped_bam.collect())

        // NM TAGS
        ADD_NM_TAGS(MERGE_MAPPED_BAMS.out.merged_sorted_bam)

        // Versions
        ch_versions = Channel.empty()
        ch_versions = ch_versions.mix(MAP_ONT_FASTQ.out.versions)
        ch_versions = ch_versions.mix(MERGE_MAPPED_BAMS.out.versions)
        ch_versions = ch_versions.mix(ADD_NM_TAGS.out.versions)
        ch_versions.unique().collectFile(name: 'map_merge_software_versions.yaml', storeDir: "${params.sampleDirectory}")

    emit:
        bam = ADD_NM_TAGS.out.bam
        bai = ADD_NM_TAGS.out.bai
        bam_md5sum =  ADD_NM_TAGS.out.md5sum
}
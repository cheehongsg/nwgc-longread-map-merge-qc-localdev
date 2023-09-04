include { MAP_ONT_BAM } from '../modules/map_ont_bam.nf'
include { MERGE_MAPPED_BAMS } from '../modules/merge_mapped_bams.nf'

workflow ONT_MAP_MERGE_BAMS {

    main:
        ontBams = Channel.empty()
         for (ontBamFolder in params.ontBamFolders) {
             bamFolderChannel = Channel.fromPath(ontBamFolder + "/*.bam")
             ontBams = ontBams.concat(bamFolderChannel)
        }
        MAP_ONT_BAM(ontBams)

        // Merge
        MERGE_MAPPED_BAMS(MAP_ONT_BAM.out.mapped_bam.collect())

        // Versions
        ch_versions = Channel.empty()
        ch_versions = ch_versions.mix(MAP_ONT_BAM.out.versions)
        ch_versions = ch_versions.mix(MERGE_MAPPED_BAMS.out.versions)
        ch_versions.unique().collectFile(name: 'map_merge_software_versions.yaml', storeDir: "${params.sampleDirectory}")

    emit:
        bam = MERGE_MAPPED_BAMS.out.merged_sorted_bam
        bai = MERGE_MAPPED_BAMS.out.bai
        bam_md5sum =  MERGE_MAPPED_BAMS.out.md5sum
}
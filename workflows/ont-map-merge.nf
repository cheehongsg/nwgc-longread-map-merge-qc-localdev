include { MAP_ONT_FASTQ } from '../modules/map_ont_fastq.nf'
include { MERGE_MAPPED_BAMS } from '../modules/merge_mapped_bams.nf'

workflow ONT_MAP_MERGE {

    main:
        ontFastqs = Channel.empty()
         for (ontFastqFolder in params.ontFastqFolders) {
             fastqFolderChannel = Channel.fromPath(ontFastqFolder + "/*.fastq.gz")
             ontFastqs = ontFastqs.concat(fastqFolderChannel)
        }
        MAP_ONT_FASTQ(ontFastqs)

        // Merge
        MERGE_MAPPED_BAMS(MAP_ONT_FASTQ.out.mapped_bam.collect())

        // Versions
        ch_versions = Channel.empty()
        ch_versions = ch_versions.mix(MAP_ONT_FASTQ.out.versions)
        ch_versions = ch_versions.mix(MERGE_MAPPED_BAMS.out.versions)
        ch_versions.unique().collectFile(name: 'map_merge_software_versions.yaml', storeDir: "${params.sampleDirectory}")

    emit:
        bam = MERGE_MAPPED_BAMS.out.merged_sorted_bam
        bai = MERGE_MAPPED_BAMS.out.bai
        bam_md5sum =  MERGE_MAPPED_BAMS.out.md5sum
}
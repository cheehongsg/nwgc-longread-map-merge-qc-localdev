
include { MAP_CCS_BAMS } from './modules/map_ccs_bams.nf'
include { MERGE_MAPPED_BAMS } from './modules/merge_mapped_bams.nf'
include { ADD_NM_TAGS } from './modules/add_nm_tags.nf'
include { SAMTOOLS_STATS } from './modules/samtools_stats.nf'
include { PICARD_QUALITY_METRICS } from './modules/picard_quality_metrics.nf'
include { PICARD_COVERAGE_METRICS } from './modules/picard_coverage_metrics.nf'

workflow PB_ANALYSIS {

    // Map the ccsBams
    def ccsBams = Channel.fromPath(params.ccsBams)
    MAP_CCS_BAMS(ccsBams)

    // Merge and add NM tags
    MERGE_MAPPED_BAMS(MAP_CCS_BAMS.out.mapped_bam.collect())
    ADD_NM_TAGS(MERGE_MAPPED_BAMS.out.merged_sorted_bam)

    // Gather statistics
    SAMTOOLS_STATS(ADD_NM_TAGS.out.nmtagged_bam)
    PICARD_QUALITY_METRICS(ADD_NM_TAGS.out.nmtagged_bam)
    PICARD_COVERAGE_METRICS(ADD_NM_TAGS.out.nmtagged_bam)
}
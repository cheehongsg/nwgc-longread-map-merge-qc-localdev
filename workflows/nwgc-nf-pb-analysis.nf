
include { MAP_CCS_BAMS } from '../modules/map_ccs_bams.nf'
include { MERGE_MAPPED_BAMS } from '../modules/merge_mapped_bams.nf'
include { ADD_NM_TAGS } from '../modules/add_nm_tags.nf'
include { SAMTOOLS_STATS } from '../modules/samtools_stats.nf'
include { PICARD_QUALITY_METRICS } from '../modules/picard_quality_metrics.nf'
include { PICARD_COVERAGE_METRICS } from '../modules/picard_coverage_metrics.nf'
include { NANO_PLOT } from '../modules/nano_plot.nf'
include { CONTAMINATION_CHECK } from '../modules/contamination_check.nf'

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
    NANO_PLOT(ADD_NM_TAGS.out.nmtagged_bam)
    CONTAMINATION_CHECK(ADD_NM_TAGS.out.nmtagged_bam)

    // Versions
    ch_versions = Channel.empty()

    ch_versions = ch_versions.mix(MAP_CCS_BAMS.out.versions)
    ch_versions = ch_versions.mix(MERGE_MAPPED_BAMS.out.versions)
    ch_versions = ch_versions.mix(ADD_NM_TAGS.out.versions)
    ch_versions = ch_versions.mix(SAMTOOLS_STATS.out.versions)
    ch_versions = ch_versions.mix(PICARD_QUALITY_METRICS.out.versions)
    ch_versions = ch_versions.mix(PICARD_COVERAGE_METRICS.out.versions)
    ch_versions = ch_versions.mix(NANO_PLOT.out.versions)
    ch_versions = ch_versions.mix(CONTAMINATION_CHECK.out.versions)

    ch_versions.unique().collectFile(name: 'software_versions.yaml', storeDir: "${params.sampleDirectory}")

}
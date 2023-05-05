
include { PB_MAP_MERGE_QC } from './workflows/nwgc-pb-map-merge-qc.nf'

workflow {
    NwgcCore.init(params)
    PB_MAP_MERGE_QC()
}

workflow.onError {
    NwgcCore.error(workflow, params.sampleId)
}

workflow.onComplete {
    NwgcCore.processComplete(workflow, params.sampleId)
}
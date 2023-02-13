process NANO_PLOT {

    label "NANO_PLOT_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleQCDirectory", mode: 'link'
 
    debug true
    module "$params.initModules"
    module "$params.pythonModule"
    memory "$params.nanoPlot.memory"
    clusterOptions "$params.defaultClusterOptions -pe serial $params.nanoPlot.numCPUs -l d_rt=1:0:0"

    input:
        path bam

    output:
        path "*.stats.txt"

    script:
        """
        mkdir -p $params.sampleQCDirectory

        NanoPlot \
            -t $params.nanoPlot.numCPUs \
            --bam $bam
        """

}

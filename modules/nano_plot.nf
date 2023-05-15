process NANO_PLOT {

    label "NANO_PLOT_${params.sampleId}_${params.userId}"

    publishDir "${params.sampleQCDirectory}/nanoPlot", mode: 'link', pattern: '*.html'
    publishDir "${params.sampleQCDirectory}/nanoPlot", mode: 'link', pattern: '*.png'
    publishDir "${params.sampleQCDirectory}/nanoPlot", mode: 'link', pattern: 'NanoStats.txt'
 
    input:
        path bam
        path bai

    output:
        path "*.html", emit: html
        path "*.png", emit: png
        path "NanoStats.txt", emit: stats
        path "versions.yaml", emit: versions

    script:
        """
        mkdir -p ${params.sampleQCDirectory}/nanoPlot

        NanoPlot \
            -t $task.cpus \
            --bam $bam

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            python: \$(python --version | awk '{print \$2}')
            NanoPlot: \$(NanoPlot --version | awk '{print \$2}')
        END_VERSIONS

        """

}

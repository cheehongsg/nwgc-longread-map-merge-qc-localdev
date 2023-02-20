# nextflow

## Envirnomental varialbles for your bash profile
| Nextflow Env Variable  	| Description 	|
|---	|---	|
| export NXF_ASSETS="/net/nwgc/vol1/software/nextflow" | # location to store  downloaded pipelines |
| export NXF_ORG="NickersonGenomeSciUW" | # github organization to look for pipelines |
| export NXF_SCM_FILE="/net/nwgc/vol1/software/nextflow/scm" | # config file for connecting to private github repo |


## SCM file for connecting to private github repo
    providers {
    
        github {
            platform = 'github'
            server = 'https://github.com'
            endpoint = 'https://api.github.com'
        }
            
    }
    
    
## NOT for this file in the long run...but we may need to use this for memory
    process my_process {
    cpus 2

    memory { 16.GB * task.attempt }
    clusterOptions "-l h_vmem=${task.memory.toMega()/cpus}M " + clusterOptions


    errorStrategy { task.exitStatus == 140 ? 'retry' : 'terminate' }
    maxRetries 3
    maxErrors -1

    ...
}
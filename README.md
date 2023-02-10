# nextflow

## Envirnomental varialbles for your bash profile
| Nextflow Env Variable  	| Description 	|
|---	|---	|
| export NXF_ASSETS="/net/grc/vol6/software/nextflow" | # location to store  downloaded pipelines |
| export NXF_ORG="NickersonGenomeSciUW" | # github organization to look for pipelines |
| export NXF_SCM_FILE="/net/grc/vol6/software/nextflow/scm" | # config file for connecting to private github repo |


## SCM file for connecting to private github repo
    providers {
    
        github {
            platform = 'github'
            server = 'https://github.com'
            endpoint = 'https://github.com'
        }
            
    }
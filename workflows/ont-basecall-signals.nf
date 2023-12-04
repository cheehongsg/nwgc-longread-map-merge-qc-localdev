import java.util.regex.Pattern
import java.util.regex.Matcher
include { MAP_ONT_BAM } from '../modules/map_ont_bam.nf'
include { MERGE_MAPPED_BAMS } from '../modules/merge_mapped_bams.nf'
include { CHECKSUM_BAM } from '../modules/checksum_bam.nf'

process CONVERT_FAST5_TO_POD5 {
    label "CONVERT_FAST5_TO_POD5_${params.sampleId}_${params.userId}"

    // keep these pod5 for future use
    publishDir "${params.ontBaseCallOutputDirectory}", mode: 'link', pattern: 'fast5_to_pod5/*.pod5'

    input:
        tuple val(chunk_idx), path('*')
    output:
        tuple val(chunk_idx), path("fast5_to_pod5/*.pod5")
    script:
        def eff_signal_path = "fast5_to_pod5/"
        """
            pod5 convert fast5 ./*.fast5 --output ${eff_signal_path} --threads 1 --one-to-one ./
        """
}

process BASECALL_ONLY_DORADO {
    label "BASECALL_ONLY_DORADO_${params.sampleId}_${params.userId}"

    // keep only the binned "pass" and "fail"
    //publishDir "${params.ontBaseCallOutputDirectory}/sup_uabams", mode: 'link', pattern: '*.uabam'

    input:
        tuple val(chunk_idx), path('*')
        val(basecaller_model)
        val(basecaller_mods)
        val(signalExtensions)
    output:
        path("${chunk_idx}.uabam"), emit: uabams
        path("*.pod5"), emit: converted_pod5s, optional: true
    script:
        def cudaDevice = (null == params.ontCudaDevice) ? 'cuda:all' : params.ontCudaDevice
        // TODO: decide if R9 or R10?
        def model_arg = (null == basecaller_model) ? "\${MODELS_ROOT}/dna_r10.4.1_e8.2_400bps_sup@v3.5.2" : "${basecaller_model}"
        def mods_arg = (null == basecaller_mods) ? '' : "--modified-bases ${basecaller_mods}"

        def eff_signal_path = "."
        """
            dorado basecaller \
                --device ${cudaDevice} \
                ${model_arg} \
                ${eff_signal_path} \
                ${mods_arg} \
            > ${chunk_idx}.uabam
        """
}

// TOCHECK
process BASECALL_WITH_DORADO {
    label "BASECALL_WITH_DORADO_${params.sampleId}_${params.userId}"
    publishDir "${params.sampleQCDirectory}/converted_pod5s", mode: 'link', pattern: '*.pod5'
    publishDir "${params.sampleQCDirectory}/uabams", mode: 'link', pattern: '*.uabam'
    input:
        tuple val(chunk_idx), path('*')
        val(basecaller_model)
        val(basecaller_mods)
        val(signalExtensions)
    output:
        path("${chunk_idx}.uabam"), emit: uabams
        path("fast5_to_pod5/*.pod5"), emit: converted_pod5s, optional: true
    script:
        def cudaDevice = (null == params.ontCudaDevice) ? 'cuda:all' : params.ontCudaDevice
        // TODO: decide if R9 or R10?
        def model_arg = (null == basecaller_model) ? "\${MODELS_ROOT}/dna_r10.4.1_e8.2_400bps_sup@v3.5.2" : "${basecaller_model}"
        def mods_arg = (null == basecaller_mods) ? '' : "--modified-bases ${basecaller_mods}"

        // TODO: check if there is a need to convert to pod5, i.e. fast5 provided
        // TODO: publish converted fast5 (i.e. pod5)
        def eff_signal_path = "fast5_to_pod5/"
        """
        if [[ "${signalExtensions}" == "fast5" ]]; then
            pod5 convert fast5 ./*.fast5 --output ${eff_signal_path} --threads ${task.cpus} --one-to-one ./
        fi

        dorado basecaller \
            --device ${cudaDevice} \
            ${model_arg} \
            ${eff_signal_path} \
            ${mods_arg} \
        > ${chunk_idx}.uabam
        """
}

// DONE
process SUMMARIZE_DORADO {
    label "SUMMARIZE_DORADO_${params.sampleId}_${params.userId}"

    // keep only the collated
    // publishDir "${params.ontBaseCallOutputDirectory}/conversion", mode: 'link', pattern: '*.summary.tsv.gz'

    input:
        path bam
    output:
        path("${bam.baseName}.summary.tsv.gz"), emit: summary
    script:
    """
        dorado summary ${bam} \
        | gzip -c \
        > ${bam.baseName}.summary.tsv.gz
    """
}

// DONE
process COLLATE_DORADO_SUMMARIES {
    label "COLLATE_DORADO_SUMMARIES_${params.sampleId}_${params.userId}"

    publishDir "${params.ontBaseCallOutputDirectory}", mode: 'link', pattern: '*.summary.tsv.gz'

    input:
        path tsvs
    output:
        path("${params.sampleId}.${params.sequencingTarget}.summary.tsv.gz"), emit: summary
    shell:
    '''
        n=0
        for fname in !{tsvs}; do
            if [ $n -eq 0 ]; then
                n=1
                zcat $fname
            else
                zcat $fname | tail -n +2
            fi
        done \
        | gzip -c \
        > !{params.sampleId}.!{params.sequencingTarget}.summary.tsv.gz
    '''
}

// DONE
process QSFILTER {
    label "QSFILTER_${params.sampleId}_${params.userId}"

    publishDir "${params.ontBaseCallOutputDirectory}/sup_uabams_pass", mode: 'link', pattern: '*.pass.bam'
    publishDir "${params.ontBaseCallOutputDirectory}/sup_uabams_fail", mode: 'link', pattern: '*.fail.bam'
    
    input:
        path reads
        val(qscore_filter)
    output:
        path("${reads.baseName}.pass.bam"), emit: pass
        path("${reads.baseName}.fail.bam"), emit: fail
    script:
    """
        samtools view \
            -@ ${task.cpus} \
            -e '[qs] >= ${qscore_filter}' \
            ${reads} \
            -o ${reads.baseName}.pass.bam \
            -U ${reads.baseName}.fail.bam
    """
}

workflow ONT_BASECALL_SIGNALS {
    main:
        // def signalExtensions = '{fast5,pod5}'
        // our default naming is: PAM05070_pass_c2f39984_a1f291a3_0
        def pattern_FC_PF_runid_acqid_chunkid = /[A-Z]{3}[0-9]{5}_(pass|fail)_[0-9a-zA-Z]{8}_[A-Za-z0-9]{8}_[0-9]*/

        // TODO: null
        // ${MODELS_ROOT}
        basecaller_model = file(params.ontBaseCallModel, type: "dir")
        log.info "Basecaller model = ${basecaller_model}"

        basecaller_mods = params.ontBaseCallBaseModifications
        log.info "Basecaller modifications = ${basecaller_mods}"

        Integer chunk_idx = 0
        ontSignals_chunks = Channel.empty()
        for (ontSignalFolder in params.ontSignalFolders) {
            signalFolderChannel = Channel.fromPath(ontSignalFolder + "/*.${params.signalExtensions}", checkIfExists: true)
            ontSignals_chunks = ontSignals_chunks.concat(signalFolderChannel)
        }
        ontSignals_chunks
            .toSortedList()
            .flatten()
            .branch{
                pattern_FC_PF_runid_acqid_chunkid: it.baseName ==~ pattern_FC_PF_runid_acqid_chunkid
                no_pattern: true
            }.set{signal_name_types}
        /*
        signal_name_types.pattern_FC_PF_runid_acqid_chunkid.subscribe { 
            log.info "signal_name_types.pattern_FC_PF_runid_acqid_chunkid = ${it.baseName}"
        }
        */
        signal_name_types.no_pattern.first().subscribe { 
            log.warn "Unexpected signal file naming convention detected. ${it.baseName}"
        }

        // Split the name keeping the flow cell, run, pass/fail and pod5 index.
        signal_name_types.pattern_FC_PF_runid_acqid_chunkid
            .map{filename -> 
                fields = filename.baseName.split("_")
                [fields[-1] as int, fields[0], fields[3], fields[1], filename]
            }
            .map{ pod5_index, cell_id, run_id, pass, pod5 ->
                [Math.floor(pod5_index/params.basecaller_num_chunk_per_batch), cell_id, run_id, pass, pod5]
            }
            .groupTuple(
                by: [0, 1, 2, 3]
            )
            .map{pod5_index, cell_id, run_id, pass, pod5s -> pod5s}
            .mix(
                signal_name_types.no_pattern
                    .buffer(size:params.basecaller_num_chunk_per_batch, remainder: true)
            )
            .map { pod5s -> [chunk_idx++, pod5s] }
            .set{ontSignalsBatches}

        if ((null == basecaller_model)) {
            // TODO: decide if R9 or R10?
            basecaller_model = "\${MODELS_ROOT}/dna_r10.4.1_e8.2_400bps_sup@v3.5.2"
            log.info("No basecaller model specified. Defaul to ${basecaller_model}")
        } else {
            if (!basecaller_model.exists()) {
                log.info("Specified basecaller model ${basecaller_model} not found.")
                basecaller_model = "\${MODELS_ROOT}/${basecaller_model.name}"
                log.info("Override to ${basecaller_model}")
            } else {
                log.info("Using specified basecaller model ${basecaller_model}")
            }
        }


        /*
        called_bams = BASECALL_WITH_DORADO(
            ontSignalsBatches,
            basecaller_model,
            basecaller_mods,
            params.signalExtensions
        )
        */
        if (params.signalExtensions == "fast5") {
            pod5conversion = CONVERT_FAST5_TO_POD5(ontSignalsBatches)
            called_bams = BASECALL_ONLY_DORADO(
                pod5conversion, 
                basecaller_model,
                basecaller_mods,
                params.signalExtensions)
        } else {
            called_bams = BASECALL_ONLY_DORADO(
                ontSignalsBatches,
                basecaller_model,
                basecaller_mods,
                params.signalExtensions
            )
        }

        // Compute summary
        SUMMARIZE_DORADO(called_bams.uabams) | collect | COLLATE_DORADO_SUMMARIES    
        summary = COLLATE_DORADO_SUMMARIES.out.summary

        // collate pass and fail
        crams = QSFILTER(called_bams.uabams, params.basecall_qscore_filter)

        // TODO: should merge the fail for SV processing!!
        // perform the mapping on the pass
        MAP_ONT_BAM(crams.pass)

        // Merge
        MERGE_MAPPED_BAMS(MAP_ONT_BAM.out.mapped_bam.collect())

        // checksum
        CHECKSUM_BAM(MERGE_MAPPED_BAMS.out.merged_sorted_bam)

        // Versions
        ch_versions = Channel.empty()
        ch_versions = ch_versions.mix(MAP_ONT_BAM.out.versions)
        ch_versions = ch_versions.mix(MERGE_MAPPED_BAMS.out.versions)
        ch_versions = ch_versions.mix(CHECKSUM_BAM.out.versions)
        ch_versions.unique().collectFile(name: 'map_merge_software_versions.yaml', storeDir: "${params.sampleDirectory}")

    emit:
        chunked_pass_crams = crams.pass
        chunked_fail_crams = crams.fail
        summary = summary
        converted_pod5s = called_bams.converted_pod5s
        // from second phase
        bam = MERGE_MAPPED_BAMS.out.merged_sorted_bam
        bai = MERGE_MAPPED_BAMS.out.bai
        bam_md5sum =  CHECKSUM_BAM.out.md5sum
}

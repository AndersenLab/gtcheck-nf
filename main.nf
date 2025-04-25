nextflow.enable.dsl=2

// Needed to publish results
nextflow.preview.output = true

date = new Date().format( 'yyyyMMdd' )

def getGenomeAttribute(attribute, required=true) {
    if (params.genomes && params.species && params.genomes.containsKey(params.species)) {
        if (params.genomes[ params.species ].containsKey(attribute)) {
            return params.genomes[ params.species ][ attribute ]
        } else if (required) {
            println "${attribute} is missing from genome map"
            exit 1
        }
    } else if (required == true) {
        println "Must have --species defined and present in --genomes map"
        exit 1
    }
    return null
}

if (params.help == false){
    if (params.sample_sheet == null || params.sample_dir == null){
        println "Both sample_sheet and sample_dir must be defined"
        exit 1
    }
    if (params.strain_dir == null){
        if (params.species == null || params.release == null){
            println "Either strain_dir or species and release must be defined"
            exit 1
        } else {
            variation_dir = getGenomeAttribute('variation_dir')
            strain_dir = "${variation_dir}/${params.release}/vcf/strain_vcf"
        }
    } else {
        strain_dir = params.strain_dir
    }
}

def log_summary() {
/*
    Generates a log
*/

out = """

Compare new sample variants against existing samples to verify identity.
          ___                 ___                           ___                                  .-.     
         (   )               (   )                         (   )                                /    \\   
  .--.    | |_       .--.     | | .-.     .--.     .--.     | |   ___                ___ .-.    | .`. ;  
 /    \\  (   __)    /    \\    | |/   \\   /    \\   /    \\    | |  (   )              (   )   \\   | |(___) 
;  ,-. '  | |      |  .-. ;   |  .-. .  |  .-. ; |  .-. ;   | |  ' /      .------.   |  .-. .   | |_     
| |  | |  | | ___  |  |(___)  | |  | |  |  | | | |  |(___)  | |,' /      (________)  | |  | |  (   __)   
| |  | |  | |(   ) |  |       | |  | |  |  |/  | |  |       | .  '.                  | |  | |   | |      
| |  | |  | | | |  |  | ___   | |  | |  |  ' _.' |  | ___   | | `. \\                 | |  | |   | |      
| '  | |  | ' | |  |  '(   )  | |  | |  |  .'.-. |  '(   )  | |   \\ \\                | |  | |   | |      
'  `-' |  ' `-' ;  '  `-' |   | |  | |  '  `-' / '  `-' |   | |    \\ .               | |  | |   | |      
 `.__. |   `.__.    `.__,'   (___)(___)  `.__.'   `.__,'   (___ ) (___)             (___)(___) (___)     
 ( `-' ;                                                                                                 
  `.__.                                                                                               

nextflow main.nf --species=c_elegans --release=20250331 --sample_sheet=/path/to/sample/sheet --sample_dir=/path/to/samples -output-dir=/path/to/results

nextflow main.nf --strain_dir=/path/to/strain/vcfs --sample_sheet=/path/to/sample/sheet --sample_dir=/path/to/samples -output-dir=/path/to/results


    parameters           description                                              Set/Default
    ==========           ===========                                              ========================
    --species             Species: 'c_elegans', 'c_tropicalis' or 'c_briggsae'    ${params.species}
    --release             CaeNDR release for genome lookup values                 ${params.release}
    --sample_sheet        Sheet listing strain and sample vcf names, one per line ${params.sample_sheet}
    --sample_dir          Path to sample directory                                ${params.sample_dir}
    --strain_dir          Path to strain vcf directory                            ${strain_dir}
    -output-dir           Output destination directory                            ${workflow.outputDir}

    username                                                                      ${"whoami".execute().in.text}

    HELP: http://andersenlab.org/dry-guide/pipeline-CaeNDRprep   
    ----------------------------------------------------------------------------------------------
    Git info: $workflow.repository - $workflow.revision [$workflow.commitId] 
"""
out
}

log.info(log_summary())

if (params.help) {
    exit 1
}

include { BCFTOOLS_RENAME_SAMPLES } from './modules/bcftools/rename_samples/main'
include { BCFTOOLS_MERGE_VCFS     } from './modules/bcftools/merge_vcfs/main'
include { BCFTOOLS_GT_CHECK       } from './modules/bcftools/gt_check/main'
include { PYTHON_PLOT_GT          } from './modules/python/plot_gt/main'

workflow {
    main:
    ch_versions = Channel.empty()
    ch_strains = Channel.fromPath(params.sample_sheet).splitCsv(sep: "\t")
    ch_orig_strain_vcfs = ch_strains.map{ it: [[id: it[0]], "${strain_dir}/${it[0]}.vcf.gz", "${strain_dir}/${it[0]}.vcf.gz.tbi"] }
    ch_sample_strain_vcfs = ch_strains.map{ it: [[id: it[0]], "${params.sample_dir}/${it[1]}"] }

    BCFTOOLS_RENAME_SAMPLES( ch_sample_strain_vcfs )
    ch_versions = ch_versions.mix(BCFTOOLS_RENAME_SAMPLES.out.versions)

    ch_vcfs = BCFTOOLS_RENAME_SAMPLES.out.vcf.map{ it: [it[1], it[2]] }
        .collect()
        .map{ it: [[id: 'samples'], it] }
        .mix( ch_orig_strain_vcfs.map{ it: [it[1], it[2]] }
            .collect()
            .map{ it: [[id: 'strains'], it] })
    
    BCFTOOLS_MERGE_VCFS( ch_vcfs )
    ch_versions = ch_versions.mix(BCFTOOLS_MERGE_VCFS.out.versions)

    BCFTOOLS_GT_CHECK( BCFTOOLS_MERGE_VCFS.out.vcf.first(),
              BCFTOOLS_MERGE_VCFS.out.vcf.last() )
    ch_versions = ch_versions.mix(BCFTOOLS_GT_CHECK.out.versions)
    
    PYTHON_PLOT_GT( BCFTOOLS_GT_CHECK.out.gt)
    ch_versions = ch_versions.mix(PYTHON_PLOT_GT.out.versions)

    ch_versions
        .collectFile(name: 'workflow_software_versions.txt', sort: true, newLine: true)
        .set { ch_collated_versions }

    publish:
    BCFTOOLS_GT_CHECK.out.gt  >> "."
    PYTHON_PLOT_GT.out.plot   >> "."
    ch_collated_versions      >> "."
}

output {
    "." {
        mode "copy"
    }
}

workflow.onComplete {

    summary = """
    Pipeline execution summary
    ---------------------------
    Completed at: ${workflow.complete}
    Duration    : ${workflow.duration}
    Success     : ${workflow.success}
    workDir     : ${workflow.workDir}
    exit status : ${workflow.exitStatus}
    Error report: ${workflow.errorReport ?: '-'}
    Git info: $workflow.repository - $workflow.revision [$workflow.commitId]
    { Parameters }
    ---------------------------
    Species: ${params.species}
    Release: ${params.release}
    Sample_sheet: ${params.sample_sheet}
    Sample_dir: ${params.sample_dir}
    Strain_dir: ${strain_dir}
    Output-dir: ${workflow.outputDir}
    """

    println summary
}

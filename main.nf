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
    if (params.sample_dir == null){
        println "sample_dir must be defined"
        exit 1
    }
    if (params.vcf == null && (params.species == null || params.release == null)){
        println "Either vcf or species and release must be defined"
        exit 1
    }
    if (params.markers == null){
        println "markers must be defined"
        exit 1
    }
    if (params.vcf == null) {
        variation_dir = getGenomeAttribute('variation_dir')
        vcf = "${variation_dir}/${params.release}/vcf/WI.${params.release}.hard-filter.vcf.gz"
    } else {
        vcf = params.vcf
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

nextflow main.nf --vcf=/path/to/vcf --sample_sheet=/path/to/sample/sheet --sample_dir=/path/to/samples -output-dir=/path/to/results


    parameters           description                                              Set/Default
    ==========           ===========                                              ========================
    --species             Species: 'c_elegans', 'c_tropicalis' or 'c_briggsae'    ${params.species}
    --release             CaeNDR release for genome lookup values                 ${params.release}
    --sample_sheet        Sheet listing sample names and gvcf paths, one per line ${params.sample_sheet}
    --sample_dir          Path to sample directory                                ${params.sample_dir}
    --strain_sheet        Sheet listing strain names, one per line (optional)     ${params.sample_sheet}
    --vcf                 Path to strain vcf                                      ${vcf}
    --markers             Path to vcf markers                                     ${params.markers}
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

include { GVCF2BCF    } from './modules/gvcf2bcf/main'
include { MERGE_BCFS  } from './modules/merge_bcfs/main'
include { GTCHECK     } from './modules/gtcheck/main'
include { PLOT_GT     } from './modules/plot_gt/main'

// If sample_sheet not defined, use all samples in sample_dir
// If strain_sheet not defined, compare samples against all strains

workflow {
    main:
    ch_versions = channel.empty()
    channel.fromPath( params.vcf, checkIfExists: true )
        .set { ch_vcf }
    channel.fromPath( params.markers, checkIfExists: true )
        .set { ch_markers }

    if (params.sample_sheet == null) {
        ch_samples = channel.fromPath("${params.sample_dir}/*.g.vcf.gz")
            .flatten()
            .map { row -> [[id: row.split("/")[1].split(".g.")[0]], row] }
    } else {
        ch_samples = channel.fromPath(params.sample_sheet)
            .splitCsv ( sep:"\t" )
            .map { row -> [[id: row[0]], "${params.sample_dir}/${row[0]}.g.vcf.gz"]}
    }
    if (params.strain_sheet == null) {
        ch_strains = channel.of( [] )
    } else {
        ch_strains = channel.fromPath(params.strain_sheet)
    }

    GVCF2BCF( ch_samples,
              ch_markers.first() )
    ch_versions = ch_versions.mix(GVCF2BCF.out.versions)

    GVCF2BCF.out.bcf
        .map { row -> [row[1], row[2]]}
        .collect ( )
        .map { row -> [[id:"merged"], row] }
        .set { ch_sample_bcfs }

    MERGE_BCFS( ch_sample_bcfs )
    ch_versions = ch_versions.mix(MERGE_BCFS.out.versions)
    
    MERGE_BCFS.out.bcf
        .set { ch_sample_bcf }

    GTCHECK(
        ch_sample_bcf,
        ch_vcf,
        ch_strains
        )
    ch_versions = ch_versions.mix(GTCHECK.out.versions)

    PLOT_GT( GTCHECK.out.gt)
    ch_versions = ch_versions.mix(PLOT_GT.out.versions)

    ch_versions
        .collectFile(name: 'workflow_software_versions.txt', sort: true, newLine: true)
        .set { ch_collated_versions }


    publish:
    GTCHECK.out.gt       >> "."
    PLOT_GT.out.plot     >> "."
    ch_collated_versions >> "."
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
    Strain_sheet: ${params.strain_sheet}
    Strain_vcf: ${vcf}
    Markers: ${params.markers}
    Output-dir: ${workflow.outputDir}
    """

    println summary
}

# gtcheck-nf

This pipeline performs a comparison of new sample variants against existing samples to verify identity.

# Pipeline overview

```
          ___                 ___                           ___                                  .-.     
         (   )               (   )                         (   )                                /    \   
  .--.    | |_       .--.     | | .-.     .--.     .--.     | |   ___                ___ .-.    | .`. ;  
 /    \  (   __)    /    \    | |/   \   /    \   /    \    | |  (   )              (   )   \   | |(___) 
;  ,-. '  | |      |  .-. ;   |  .-. .  |  .-. ; |  .-. ;   | |  ' /      .------.   |  .-. .   | |_     
| |  | |  | | ___  |  |(___)  | |  | |  |  | | | |  |(___)  | |,' /      (________)  | |  | |  (   __)   
| |  | |  | |(   ) |  |       | |  | |  |  |/  | |  |       | .  '.                  | |  | |   | |      
| |  | |  | | | |  |  | ___   | |  | |  |  ' _.' |  | ___   | | `. \                 | |  | |   | |      
| '  | |  | ' | |  |  '(   )  | |  | |  |  .'.-. |  '(   )  | |   \ \                | |  | |   | |      
'  `-' |  ' `-' ;  '  `-' |   | |  | |  '  `-' / '  `-' |   | |    \ .               | |  | |   | |      
 `.__. |   `.__.    `.__,'   (___)(___)  `.__.'   `.__,'   (___ ) (___)             (___)(___) (___)     
 ( `-' ;                                                                                                 
  `.__.                                                                                               

nextflow main.nf --species=c_elegans --release=20250331 --sample_sheet=/path/to/sample/sheet --sample_dir=/path/to/samples -output-dir=/path/to/results

nextflow main.nf --strain_dir=/path/to/strain/vcfs --sample_sheet=/path/to/sample/sheet --sample_dir=/path/to/samples -output-dir=/path/to/results

    parameters           description                                              Set/Default
    ==========           ===========                                              ========================
    --help                Set to 'true' for usage                                 false
    --species             Species: 'c_elegans', 'c_tropicalis' or 'c_briggsae'    (required if strain_dir not defined)
    --release             CaeNDR release for genome lookup values                 (required if strain_dir not defined)
    --sample_sheet        Sheet listing sample vcf names, one per line            (required)
    --sample_dir          Path to sample directory                                (required)
    --strain_dir          Path to strain vcf directory                            (required if species or release no defined)
    -output-dir           Output destination directory                            GTcheck_{date}

    username                                                                      ${"whoami".execute().in.text}

```

## Software Requirements

* The latest update requires Nextflow version 24.10.0+. On Rockfish, you can access this version by loading the `nf24_env` conda environment prior to running the pipeline command:

```
ml anaconda
conda activate /data/eande106/software/conda_envs/nf24_env
```

# Usage

*Note: if you are having issues running Nextflow or need reminders, check out the [Nextflow](http://andersenlab.org/dry-guide/latest/rockfish/rf-nextflow/) page.*

## Testing on Rockfish

*This command uses a test dataset*

```
nextflow run -latest andersenlab/caendrprep-nf --debug
```

>[!Note]
> This is not currently implemented

## Running on Rockfish

You should run this in a screen or tmux session.

```
nextflow andersenlab/gtcheck-nf --species=c_elegans --release=20250331 --sample_sheet=/path/to/sample/sheet --sample_dir=/path/to/sample/dir
```

# General Parameters

##  --species (optional if strain_dir specified)

If the directory containing strain VCFs is not specified, the species and release date can be used to look up existing files for c_elegans, c_briggsae, or c_tropicalis

## --release (optional if strain_dir specified)

If the directory containing strain VCFs is not specified, the species and release date can be used to look up existing files for c_elegans, c_briggsae, or c_tropicalis

## --sample_sheet (required)

Path to sample sheet containing list of VCF sample names, one per line

## --sample_dir (required)

Path to folder containing sample VCF files

## --strain_dir (optional if species and release are specified)

Path to folder containing strain VCF files

## -output-dir (default: GTcheck_{date})

Output destination directory                            

# Output

```
├── gtcheck.txt
└── gtcheck.pdf
```

# Relevant docker images
* `quay.io-biocontainers-bcftools-1.16--hfe4b78e_1` ([link](https://quay.io/biocontainers/bcftools:1.16--hfe4b78e_1)): Docker image maintained by Biocontainer for BCFtools
* `andersenlab/numpy` ([link](https://hub.docker.com/r/andersenlab/numpy)): Docker image is created within this pipeline using GitHub actions. Whenever a change is made to `env/Dockerfile` or `.github/workflows/build_docker.yml` GitHub actions will create a new docker image and push if successful

Make sure that you have followed the [Nextflow configuration](https://andersenlab.org/dry-guide/latest/rockfish/rf-nextflow/) described in the dry-guide prior to running the workflow.

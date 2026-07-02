process GTCHECK {

    label 'gtcheck'
    container "docker://quay.io/biocontainers/bcftools:1.16--hfe4b78e_1"

    input:
    tuple val(meta), path(sample_bcf)
    path strain_vcf
    path strains

    output:
    path "gtcheck.tsv"  , emit: gt
    path "versions.yml" , emit: versions
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def strain_names = strains ? "-S gt:${strains}" : ''
    """
    bcftools gtcheck --no-HWE-prob -e 0 ${sample_bcf} -g ${strain_vcf} ${strain_names} -o gtcheck.tsv
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_gtcheck.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}

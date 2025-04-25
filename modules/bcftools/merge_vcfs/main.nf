process BCFTOOLS_MERGE_VCFS {

    tag "${meta.id}"

    input:
        tuple val(meta), path("*")

    output:
        tuple val(meta), path("${meta.id}_merged.vcf.gz"), path("${meta.id}_merged.vcf.gz.tbi"), emit: vcf

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    bcftools merge *.vcf.gz -Oz -o ${meta.id}_merged.vcf.gz
    bcftools index -t ${meta.id}_merged.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_merged.vcf.gz
    touch ${meta.id}_merged.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}

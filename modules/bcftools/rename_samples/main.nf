process BCFTOOLS_RENAME_SAMPLES {

    tag "${meta.id}"

    input:
        tuple val(meta), path(vcf)

    output:
        tuple val(meta), path("${meta.id}_renamed.vcf.gz"), path("${meta.id}_renamed.vcf.gz.tbi"), emit: vcf

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    cat ${vcf} | \\
    awk 'BEGIN{OFS="\\t"}{if (\$1 ~ /^#CHROM/) \$10="${meta.id}"; print \$0}' | \\
    bcftools view -Oz > ${meta.id}_renamed.vcf.gz

    bcftools index -t ${meta.id}_renamed.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_renamed.vcf.gz
    touch ${meta.id}_renamed.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}

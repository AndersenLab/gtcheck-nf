process BCFTOOLS_GT_CHECK {


    input:
        tuple val(meta1), path("merged1.vcf.gz"), path("merged1.vcf.gz.tbi")
        tuple val(meta2), path("merged2.vcf.gz"), path("merged2.vcf.gz.tbi")

    output:
        path "gtcheck.txt", emit: gt

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def avail_mem = (task.memory.giga).intValue() - 1
    """
    if [[ ${meta1.id} == "samples" ]]; then
        SAMPLES="${meta1.id}"
        STRAINS="${meta2.id}"
    else
        SAMPLES="${meta2.id}"
        STRAINS="${meta1.id}"
    fi

    bcftools gtcheck --no-HWE-prob -E 0 --g \${STRAINS} \${SAMPLES} > gtcheck.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch gtcheck.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}

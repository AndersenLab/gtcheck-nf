process MERGE_BCFS {

    tag "${meta.id}"
    container "docker://quay.io/biocontainers/bcftools:1.16--hfe4b78e_1"

    input:
        tuple val(meta), path("*")

    output:
        tuple val(meta), path("${meta.id}.bcf"), path("${meta.id}.bcf.csi"), emit: bcf
        path "versions.yml"                                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    BCFS=(*.bcf)
    if (( \${#BCFS[*]} > 1 )); then
        bcftools merge *.bcf -Ob -o ${meta.id}.bcf
    else
        cp \${BCFS[0]} ${meta.id}.bcf
    fi
    bcftools index -c ${meta.id}.bcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_merged.bcf
    touch ${meta.id}_merged.bcf.csi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}

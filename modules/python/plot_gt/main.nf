process PYTHON_PLOT_GT {


    input:
        path "gtcheck.txt"

    output:
        path "gtcheck.pdf", emit: plot

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def avail_mem = (task.memory.giga).intValue() - 1
    """
    cat gtcheck.txt | awk 'BEGIN{OFS="\\t"}{if (\$1 == "DC") print \$4,\$6,\$2,\$3}' > gtcheck_filtered.txt
    python -c "\\
    import numpy; \\
    import matplotlib.pyplot as plt; \\
    data = numpy.loadtxt('gtcheck_filtered.txt', dtype=numpy.dtype([('differences', numpy.int32), ('sites', numpy.int32), ('sample', 'U8'), ('strain', 'U8')])); \\
    strains = numpy.unique(data['sample']); \\
    concordance = numpy.zeros((len(strains), len(strains)), numpy.float32); \\
    index1 = numpy.searchsorted(strains, data['sample']); \\
    index2 = numpy.searchsorted(strains, data['strain']); \\
    concordance[index1, index2] = 1 - data['differences'] / data['sites']; \\
    fig, ax = plt.subplots(1, 1, figsize=(len(strains) * 0.5 + 2, len(strains) * 0.5 + 2)); \\
    ax.imshow(concordance); \\
    ax.set_xticks(numpy.arange(len(strains))); \\
    ax.set_xticklabels(list(strains), rotation=45, ha='right', va='top'); \\
    ax.set_xlabel('Existing strains'); \\
    ax.set_yticks(numpy.arange(len(strains))); \\
    ax.set_yticklabels(list(strains)); \\
    ax.set_ylabel('New samples'); \\
    ax.set_title('Concordance'); \\
    plt.tight_layout(); \\
    plt.savefig('gtcheck.pdf'); \\
    "

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$( python --version |& cut -f2 )
    END_VERSIONS
    """

    stub:
    """
    touch gtcheck.pdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$( python --version |& cut -f2 )
    END_VERSIONS
    """
}

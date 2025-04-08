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
    python -m "\\
    import numpy;\\
    import matplotlib.pyplot as plt;\\
    data = numpy.loadtxt(skiprows=1, dtype=[('differences', numpy.int32), ('sites', numpy.int32), ('sample', 'U8'), ('strain', 'U8')]);\\
    strains = list(numpy.unique(data['sample']));\\
    concordance = numpy.zeros((len(strains), len(strains)), numpy.float32);\\
    [concordance[strains.index(data['sample'][x]), strains.index(data['strain'][x])] = 1 - data['differences'][x] / data['sites'][x] for x in range(data.shape[0])];\\
    concordance += concordance.T;\\
    concordance[numpy.arange(len(strains)), numpy.arange(len(strains))] = 1;\\
    fig, ax = plt.subplots(1, 1, figsize=(len(strains) * 0.5 + 2, len(strains) * 0.5 + 2));\\
    ax.imshow(concordance);\\
    ax.set_xticks(numpy.arange(len(strains)));\\
    ax.set_xticklabels(strains, rotation=45, ha='right', va='top');\\
    ax.set_xlabel('Existing strains');\\
    ax.set_yticks(numpy.arange(len(strains)));\\
    ax.set_yticklabels(strains);\\
    ax.set_ylabel('New samples');\\
    plt.savefig('gtcheck.pdf');\\
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

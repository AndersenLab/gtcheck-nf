process GVCF2BCF {

    tag "${meta.id}"
    label 'gvcf2bcf'
    errorStrategy 'retry'
    time { 1.hour * task.attempt }
    cpus { 1 * task.attempt }
    container "docker://quay.io/biocontainers/bcftools:1.16--hfe4b78e_1"

    input:
    tuple val(meta), path(gvcf)
    path markers

    output:
    tuple val(meta), path("${meta.id}.bcf"), path("${meta.id}.bcf.csi") , emit: bcf
    path "versions.yml"                                                 , emit: versions
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    zcat ${gvcf} | awk '{
        if (FNR == NR) {
            MARKERS[\$1 " " \$2] = \$3 "\\t" \$4;
        } else {
            if (\$1 ~ /^#/) {
                print \$0;
            } else {
                if (\$6 == ".") {
                    split(\$8,STOP_ARR,"=");
                    STOP=STOP_ARR[2];
                    for (I=\$2;I<=STOP;I++) {
                        MARKER=\$1 " " I;
                        if (MARKER in MARKERS) {
                            ALLELE=MARKERS[MARKER];
                            printf "%s\\t%s\\t.\\t%s\\t.\\tPASS\\t.\\tGT\\t0/0\\n", \$1, I, ALLELE;
                        }
                    }
                } else {
                    split(\$9,FORMAT,":");
                    split(\$10,SAMPLE,":");
                    split(\$5,ALT_ARR,",");
                    ALT=ALT_ARR[1];
                    for (I=1;I<=length(FORMAT);I++){
                        FORMAT_ID=FORMAT[I];
                        if (FORMAT_ID == "GT") {
                            GT=SAMPLE[I];
                        } else if (FORMAT_ID == "GQ") {
                            GQ=SAMPLE[I];
                        } else if (FORMAT_ID == "AD") {
                            split(SAMPLE[I],AD,",");
                        } else if (FORMAT_ID == "PL") {
                            split(SAMPLE[I],PL,",");
                        }
                    }
                    printf "%s\\t%s\\t.\\t%s\\t%s\\t%s\\tPASS\\t.\\tGT:GQ:AD:PL\\t%s:%s:%s,%s:%s,%s,%s\\n", \$1, \$2, \$4, ALT, \$6, GT, GQ, AD[1], AD[2], PL[1], PL[2], PL[3];
                }
            }
        }
    }' ${markers} - | bcftools view -Ob > ${meta.id}.bcf
    bcftools index -c ${meta.id}.bcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.bcf
    touch ${meta.id}.bcf.csi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}

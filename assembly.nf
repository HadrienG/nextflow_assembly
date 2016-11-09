#!/usr/bin/env nextflow

params.reads = 'data/ERR486840_1.fastq.gz'
params.adapt = 'data/adapters.fasta'
params.mode = 'illumina'

sequences = file(params.reads)
adapters = file(params.adapt)

process adapter_trimming {
    input:
    file input from sequences
    file 'adapters.fasta' from adapters

    output:
    file "${input.baseName}.adapt" into adapt_trimmed

    script:
	if( params.mode == 'illumina' )
		"""
		scythe -q sanger -a adapters.fasta -o "${input.baseName}.adapt" $input
		"""
	else if( params.mode == 'ion' )
        """
        cp $input "${input.baseName}.adapt"
        """
    else
        error "Invalid alignment mode: ${params.mode}"

}

process quality_trimming {
    input:
    file input from adapt_trimmed

    output:
    file "${input.baseName}.trimmed" into trimmed

    """
    sickle se -f $input -t sanger -o "${input.baseName}.trimmed" -q 20
    """
}

process assembly {
    publishDir 'results'

    input:
    file input from trimmed

    output:
    file "assembly/contigs.fa" into assembly

    """
    velveth assembly 55 -fmtAuto -short $input
    velvetg assembly -cov_cutoff auto -min_contig_lgth 500 -exp_cov auto
    """
}

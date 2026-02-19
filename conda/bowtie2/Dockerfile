FROM continuumio/miniconda3:4.9.2 AS conda

COPY environment.yml .

RUN conda env create -f environment.yml && \
    conda clean -afy


FROM centos:7

COPY --from=conda /opt/conda/envs/bowtie2 /opt/conda/envs/bowtie2

ENV PATH=/opt/conda/envs/bowtie2/bin:$PATH
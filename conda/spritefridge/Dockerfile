FROM continuumio/miniconda3:4.9.2 AS conda

COPY environment.yml .

RUN conda env create -f environment.yml && \
    conda clean -afy


FROM centos:latest

COPY --from=conda /opt/conda/envs/sprite /opt/conda/envs/sprite

ENV PATH=/opt/conda/envs/sprite/bin:$PATH
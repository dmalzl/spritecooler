FROM continuumio/miniconda3:4.9.2 AS conda

COPY environment.yml .

RUN conda env create -f environment.yml && \
    conda clean -afy


FROM centos:7

COPY --from=conda /opt/conda/envs/coolplotter /opt/conda/envs/coolplotter

ENV PATH=/opt/conda/envs/coolplotter/bin:$PATH
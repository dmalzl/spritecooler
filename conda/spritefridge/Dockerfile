FROM continuumio/miniconda3:4.9.2

COPY environment.yml .

RUN conda env create -f environment.yml && \
    conda clean -afy


ENV PATH=/opt/conda/envs/spritefridge/bin:$PATH
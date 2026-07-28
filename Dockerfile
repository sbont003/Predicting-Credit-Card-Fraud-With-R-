FROM rocker/r-ver:4.4.1

WORKDIR /project
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/install_packages.R /tmp/install_packages.R
RUN Rscript /tmp/install_packages.R

COPY . /project
ENV FULL_DATA=0
CMD ["Rscript", "scripts/run_pipeline.R"]

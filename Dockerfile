FROM python:3.10-slim as build

ENV PIP_DEFAULT_TIMEOUT=100 \
    # Allow statements and log messages to immediately appear
    PYTHONUNBUFFERED=1 \
    # disable a pip version check to reduce run-time & log-spam
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    # cache is useless in docker image, so disable to reduce image size
    PIP_NO_CACHE_DIR=1

### Final stage
FROM python:3.10-slim as final

# Set working directory
WORKDIR /app/grandqc

# Copy everything from the Docker build context (the folder with the Dockerfile)
COPY . .

RUN set -ex \
    # Upgrade the package index and install security upgrades
    && apt-get update \
    && apt-get upgrade -y \
    # Install dependencies
    && apt-get install procps -y \
    && apt-get install wget -y \
    && apt-get install unzip -y \
    && pip install -r requirements.txt \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Create central models directory
RUN mkdir -p /app/grandqc/models/qc \
    /app/grandqc/models/td

# Download models from Zenodo
RUN wget -O /app/grandqc/models/qc/GrandQC_MPP1.pth https://zenodo.org/records/14041538/files/GrandQC_MPP1.pth \
    && wget -O /app/grandqc/models/qc/GrandQC_MPP15.pth https://zenodo.org/records/14041538/files/GrandQC_MPP15.pth \
    && wget -O /app/grandqc/models/qc/GrandQC_MPP2.pth https://zenodo.org/records/14041538/files/GrandQC_MPP2.pth \
    && wget -O /app/grandqc/models/td/Tissue_Detection_MPP10.pth https://zenodo.org/records/14507273/files/Tissue_Detection_MPP10.pth

# Symlink models into the respective subdirectories
RUN mkdir -p /app/grandqc/01_WSI_inference_OPENSLIDE_QC/models \
    /app/grandqc/02_WSI_inference_OME_TIFF_QC/models \
    && ln -sf /app/grandqc/models/* /app/grandqc/01_WSI_inference_OPENSLIDE_QC/models/ \
    && ln -sf /app/grandqc/models/* /app/grandqc/02_WSI_inference_OME_TIFF_QC/models/
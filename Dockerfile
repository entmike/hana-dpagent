FROM ubuntu:18.04
RUN apt-get update && apt-get install -y unzip iputils-ping wget

# Download SAP JVM and Copy HXE Download Manager
WORKDIR /software
RUN wget --no-check-certificate --no-cookies --header "Cookie: eula_3_1_agreed=tools.hana.ondemand.com/developer-license-3_1.txt; path=/;" -S https://tools.hana.ondemand.com/additional/sapjvm-8.1.055-linux-x64.zip
COPY ./files/HXEDownloadManager_linux.bin /software/HXEDownloadManager_linux.bin
RUN unzip sapjvm-8.1.055-linux-x64.zip

# Create DP Agent User
RUN groupadd -r dpagent && useradd -r -m -g dpagent dpagent 
USER dpagent
WORKDIR /home/dpagent

# Install Software
ENV PATH="/software/sapjvm_8/jre/bin:${PATH}"
RUN cp /software/HXEDownloadManager_linux.bin . && \
       ./HXEDownloadManager_linux.bin -d . linuxx86_64 vm dpagent_linux_x86_64.tgz && \
       tar -xvf dpagent_linux_x86_64.tgz && \
       rm dpagent_linux_x86_64.tgz && \
       ./HANA_EXPRESS_20/DATA_UNITS/HANA_DP_AGENT_20_LIN_X86_64/hdbinst --batch --path=/home/dpagent/dataprovagent && \
       rm -Rf ./HANA_EXPRESS_20

# Copy over DB JARs
COPY ./files/sdi-libs/* /home/dpagent/dataprovagent/lib/

# Setup Entry Point
WORKDIR /home/dpagent/dataprovagent
ENTRYPOINT ./dpagent

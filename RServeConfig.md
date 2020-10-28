# RServe Quick Setup

## Building your Docker Image

1. Create the following `Dockerfile`:

```Dockerfile
FROM r-base:3.5.2
COPY . /scripts
WORKDIR /scripts

#Expose port 6311
EXPOSE 6311
CMD ["Rscript","start.R"]
```

2. In the same folder, create `start.R`:

```R
#Install Rserve
install.packages('Rserve',,"http://rforge.net/",type="source")

#Include Rserve library
library(Rserve)
#Start Rserve
run.Rserve(config.file ="Rserv.conf") # Port can also be specified in the configuration file.
```

3. Finally, create `Rserv.conf`:

```
remote enable
fileio enable
maxinbuf 500000
plaintext enable
control enable
r-control enable
port 6311
```

4. Build your image:
```bash
docker build -t hana-rserve:3.5.2 .
```
## (Optional) Run your image to test:
```bash
docker run --rm -p 6311:6311 hana-rserve:3.5.2
```

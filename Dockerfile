# https://github.com/confio/public-testnets

FROM ubuntu:20.04


ENV GOLANG_VERSION 1.18

# Install wget
RUN apt update && apt install -y build-essential wget git
# Install Go
RUN wget https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz
RUN rm -f go${GOLANG_VERSION}.linux-amd64.tar.gz

ENV PATH "$PATH:/usr/local/go/bin"

#------------------Build the tgrade binary-----------------
# Copy sources
COPY . ./

# Install Alpine Dependencies
#RUN apk update && apk upgrade && apk add --update alpine-sdk && \
#    apk add --no-cache bash git openssh make cmake 

RUN ls -lah

RUN git clone https://github.com/confio/tgrade
WORKDIR "./tgrade"
RUN ls -lah
RUN git checkout v0.9.0
# Run GO install and build for the upcoming binary
RUN make build
# Move the binary to an executable path
RUN mv build/tgrade /usr/local/bin


#------------------Setting up a Genesis Tgrade Validator - PHASE 1-----------------
# Initialize your genesis and configuration files for all validators nodes
RUN tgrade init my-validator --chain-id tgrade-dryrunnet --home /opt/validator/.tgrade
# Import your Validator Key
#TODO::VVV RUN tgrade keys add my-validator --recover --home /opt/validator/.tgrade
#TODO::VVV remov the following
RUN mkdir -p ~/opt/validator/.tgrade/config/
# Get the genesis file and moved to the right location
RUN wget https://raw.githubusercontent.com/confio/public-testnets/main/dryrunnet/config/pre-genesis.json -O ~/opt/validator/.tgrade/config/genesis.json

#Setup the right parameters and values on the TOML files
#Please edit the config/app.toml and config/config.toml accordingly
#- app.toml: set minimum-gas-prices
#  minimum-gas-prices = "0.05utgd"

#- config.toml: set persistent_peers and other suggested changes
#  moniker = "<your validator name>"
#  persistent_peers = "9c70e7fb4237de7dfb842c51d0c8a2bee6b843c0@168.119.252.165:26656,f0976ec13d3498397b0a891b44c9a024f8eebb4a@188.34.162.243:26656,ee664babe18b1005fee0548c8818143e745ad80a@142.132.225.3:26656"


#------------------Create genesis txs - PHASE 2-----------------
# We need to collect from the genesis validators:
# node-id tgrade tendermint show-node-id
# pubkey tgrade tendermint show-validator
# IP and port to be used
# node-id, pubkey and home values are just examples, please change it accordingly to your system/validator
RUN tgrade gentx my-validator 0utgd 90000000utgd \
  --amount 0utgd \
  --vesting-amount 90000000utgd \
  --fees 10000utgd \
  --moniker my-validator \
  --node-id $(tgrade tendermint show-node-id) \
  --chain-id tgrade-dryrunnet \
  --home /opt/validator/.tgrade

# Upload your Gen_TX
# The above will create a gentx file. We are going to need it for the genesis collect.

#1 Fork the repo: https://github.com/confio/public-testnets , clicking on fork, and choose your account
#2 Clone your fork copy to your local machine
#3 Copy the gentx file into ../dryrunnet/config/gentx/
#4 Commit and push the repo
#5 Create a pull request from your fork to the main repo
#6 Inform us on the discord channel

#------------------Create genesis txs - PHASE 3-----------------
# Get the final genesis file
RUN wget https://raw.githubusercontent.com/confio/public-testnets/main/dryrunnet/config/genesis.json -O ~/.tgrade/config/genesis.json

# Start the syncing

# Build runtime image
#FROM golang:alpine AS run-env

#WORKDIR /app
#COPY --from=build-env /app/out .
#EXPOSE 5000

#ENTRYPOINT ["tgrade", "start", "--rpc.laddr tcp://0.0.0.0:26657", "--home /opt/validator/.tgrade"]

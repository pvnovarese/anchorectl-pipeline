# Using anchorectl in CI Pipelines

[![Anchore Enterprise with anchorectl](https://github.com/pvnovarese/anchorectl-pipeline/actions/workflows/anchorectl-enterprise.yaml/badge.svg)](https://github.com/pvnovarese/anchorectl-pipeline/actions/workflows/anchorectl-enterprise.yaml)

This is a very rough demo of integrating Anchore with various CI pipelines using anchorectl. 


## Introduction

```
curl.....
```

anchorectl is a command line interface tool for interacting with Anchore Enterprise. For full documentation on this client, please refer to https://docs.anchore.com

This document will focus on using anchorectl with CI tooling to automate these interactions in pipelines.  

## Quickstart Install

```curl -sSfL https://anchorectl-releases.anchore.io/anchorectl/install.sh | sh -s -- -b /usr/local/bin```

This will install the latest version into /usr/local/bin

## Configuration

Many operations of anchorectl support setting configuration through environment variables, which are listed in the `--help` output for each operation when available. To codify configuration settings, you can also use a configuration file instead of environment variables - for the latest configuration file location, format and options, see:
anchorectl --help
For most pipeline scenarios, the relevant configuration variables will be:

```
ANCHORECTL_URL
ANCHORECTL_PASSWORD
ANCHORECTL_USERNAME
```

In some cases, you may also be interested in 

```
ANCHORECTL_FAIL_BASED_ON_RESULTS
```

## anchorectl Options

## Usage

## CI Implementations

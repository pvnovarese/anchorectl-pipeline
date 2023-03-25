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

This will install the latest version into /usr/local/bin.

## Configuration

Many operations of anchorectl support setting configuration through environment variables, which are listed in the `--help` output for each operation when available. To codify configuration settings, you can also use a configuration file instead of environment variables; however in CI pipelines it's generally a better practice to use environment variables populated by your CI tool's secrets/credentials features.

For most pipeline scenarios, the relevant configuration variables will be:

```
ANCHORECTL_URL         # the URL to the Anchore Enterprise API 
ANCHORECTL_USERNAME    # username to authenticate as
ANCHORECTL_PASSWORD    # password for ANCHORECTL_USERNAME
```

In some cases, you may also be interested in 

```
ANCHORECTL_FAIL_BASED_ON_RESULTS   # default false, if true, "anchorectl image check" will exit with 1 if the policy evaluation fails
```

## anchorectl Options

## Usage

There is extensive built-in help for `anchorectl` that can be accessed with `-h`.  The most common commands used in CI pipelines are:

```
anchorectl image add                # Analyze a container image
anchorectl image vulnerabilities    # Get image vulnerabilities
anchorectl image check              # Get the policy evaluation for the given image
```

## CI Implementations

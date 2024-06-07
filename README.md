# Using anchorectl in CI Pipelines

[![Anchore Enterprise with anchorectl](https://github.com/pvnovarese/anchorectl-pipeline/actions/workflows/anchorectl-enterprise.yaml/badge.svg)](https://github.com/pvnovarese/anchorectl-pipeline/actions/workflows/anchorectl-enterprise.yaml)

## Introduction

anchorectl is a command line interface tool for interacting with Anchore Enterprise.  This document covers the use of anchorectl specifically in automated pipelines.  For full documentation on this client, please refer to https://docs.anchore.com

## Quickstart Install

```curl -sSfL https://anchorectl-releases.anchore.io/anchorectl/install.sh | sh -s -- -b /usr/local/bin v5.6.0```

This will install the latest version into /usr/local/bin.  In pipeline usage, depending on tooling, you may need to install as a non-root user, in which case you can install in a location such as `${HOME}/.local/bin` or similar.  You may also need to augment your `${PATH}` depending on environment.

## Configuration

Many operations of anchorectl support setting configuration through environment variables, which are listed in the `--help` output for each operation when available. To codify configuration settings, you can also use a configuration file instead of environment variables; however in CI pipelines it's generally a better practice to use environment variables populated by your CI tool's secrets/credentials features.

For most pipeline scenarios, the relevant configuration variables will be:

```
ANCHORECTL_URL         # the URL to the Anchore Enterprise API e.g. http://localhost:8228/
ANCHORECTL_USERNAME    # username to authenticate as e.g. admin
ANCHORECTL_PASSWORD    # password for ANCHORECTL_USERNAME e.g. foobar 
```

In some cases, you may also be interested in 

```
ANCHORECTL_FAIL_BASED_ON_RESULTS   # default false, if true, "anchorectl image check" will exit with 1 if the policy evaluation fails
```


## Usage

There is extensive built-in help for `anchorectl` that can be accessed with `-h`.  The most common commands used in CI pipelines are:

```
anchorectl image add                # Analyze a container image
anchorectl image vulnerabilities    # Get image vulnerabilities
anchorectl image check              # Get the policy evaluation for the given image
```

### Verifying Connectivity and Functionality

Once you have secrets configured, users can verify that your credentials are correct, network connectivity is live, and that Anchore Enterprise is responding:

```anchorectl system status```

### Analyzing Images

There are two basic methods for analyzing images (essentially, creating the SBOM and inserting it into the catalog).  The easiest method is to have the analyzer service in the Anchore Enterprise deployment pull the image and do the analysis.  This method required that the image has been pushed to a registry that the Anchore Enterprise deployment can reach on the network, and that Anchore Enterprise has any necessary credentials for the repository in question.

```anchorectl image add ${IMAGE_NAME}```

This will add the image to the queue to be analyzed and then exit without waiting for analysis to complete.  In many cases, users will want to retreive vulnerabilities or policy compliance reports which will require waiting for the analysis to complete, in which case the user may add the `--wait` option.

```anchorectl image add --wait ${IMAGE_NAME}```

Another useful option is `--no-auto-subscribe`, which turns off the default behavior of polling the given tag to check for new images being pushed (if this is active and a new image digest is found at that tag, Anchore Enterprise will automatically pull it and analyze it).

```anchorectl image add --no-auto-subscribe ${IMAGE_NAME}```

The second method for analyzing images allows you to analyze images locally (e.g. if you haven't pushed the image to a registry, you would want to use this method).

```syft -o json ${IMAGE_NAME} | anchorectl image add ${IMAGE_NAME} --from -```

this uses `syft` to create the SBOM and then pipes that to `anchorectl` which pushes the SBOM to the Anchore Enterprise API.  Note that to use this method, you will need to install `syft` in addition to `anchorectl` as noted above.  The latest version of `syft` can be installed via

```curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b ${HOME}/.local/bin```

The `--wait` and `--no-auto-subscribe` options are valid with this method as well.

### Pulling Vulnerability Reports

To grab vulnerability reports: 

```anchorectl image vulnerabilities ${IMAGE_NAME}```

Note that if you want to parse these results programatically, you can request the results in json format with the `-o json` option, e.g.

```anchorectl -o json image vulnerabilities ${IMAGE_NAME}```


### Pulling Policy Compliance Reports

To apply the active policy bundle and get a simple pass/fail result:

```anchorectl image check ${IMAGE_NAME}```

The following options may be useful:

* `--detail` provides line-by-line feedback for every rule triggered in the policy bundle
* `-p, --policy <string>` usess the specified policy bundle instead of the active bundle
* `--f, --fail-based-on-results` sets the exit code to 1 if the policy evaluation result is "fail" (useful for breaking pipelines as a gating mechanism)
* `-o, --output json` provide results in json format for further parsing (other formats available, see help text for details)

## CI Implementations

There are samples for Jenkins, GitHub workflows, etc in this repository, but the outline of what needs to happen is essentially the same in all tools:

```
        ### first do whatever normal image build steps you would do here
        
        ### now begin the analysis and evaluation of the image
        mkdir -p ${HOME}/.local/bin
        curl -sSfL  https://anchorectl-releases.anchore.io/anchorectl/install.sh  | sh -s -- -b $HOME/.local/bin  
        export PATH="${HOME}/.local/bin/:${PATH}"
        anchorectl image add --wait ${IMAGE_NAME}
        anchorectl image vulnerabilities ${IMAGE_NAME}
        anchorectl image check -f --detail ${IMAGE_NAME}
        
        ### now if the image passed the policy check on the previous line, we
        ### can continue our pipeline (e.g. push to QA, promote image to 
        ### another registry, etc).
```

## Advanced Usage

Beyond just simple policy checks, you may want to activate subscriptions on your new image.  This will begin continuous updates of the vulnerability matches and/or policy evaluation in the background (this is most useful when coupled with the "Notifications" facility of Anchore Enterprise, see the [Notifications documentation](https://docs.anchore.com/current/docs/configuration/notifications/) for more details):

```
        ### begin continuous updates of vulnerability matches
        anchorectl subscription activate ${IMAGE_NAME} vuln_update
        
        ### begin continuous updates of policy evaluation
        anchorectl subscription activate ${IMAGE_NAME} policy_eval   
```

In either case, if new vulnerability matches are found or the pass/fail policy result changes, an event is created which can trigger notifications, hit a webhook, etc.

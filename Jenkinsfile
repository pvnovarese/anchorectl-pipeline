// requires anchorectl
// requires anchore enterprise 
//
pipeline {
  environment {
    // set some variables
    //
    // we don't need registry if using docker hub
    // but if you're using a different registry, set this 
    REGISTRY = 'docker.io'
    //
    //
    // you will need a credential with your docker hub user/pass
    // (or whatever registry you're using) and a credential with
    // user/pass for your anchore instance:
    // ...
    // first let's set the docker hub credential and extract user/pass
    // we'll use the USR part for figuring out where are repository is
    HUB_CREDENTIAL = "docker-hub"
    // use credentials to set DOCKER_HUB_USR and DOCKER_HUB_PSW
    DOCKER_HUB = credentials("${HUB_CREDENTIAL}")
    // we'll need the anchore credential to pass the user
    // and password to anchorectl so it can upload the results
    ANCHORE_CREDENTIAL = "AnchorectlCredential"
    // use credentials to set ANCHORE_USR and ANCHORE_PSW
    ANCHORE = credentials("${ANCHORE_CREDENTIAL}")
    //
    // now set the actual envvars that anchorectl uses:
    ANCHORECTL_USERNAME = "${ANCHORE_USR}"
    ANCHORECTL_PASSWORD = "${ANCHORE_PSW}"
    //
    // api endpoint of your anchore instance (anchore-cli needs the trailing /v1,
    // anchorectl doesn't want the /v1)
    // we could hardcode these eg:
    // ANCHORECTL_URL = "http://anchore33-priv.novarese.net:8228"
    // but I have a secret text credential called AnchorectlURL:
    ANCHORECTL_URL = credentials("AnchorectlUrl")
    //
    // assuming you want to use docker hub, this shouldn't need
    // any changes, but if you're using another registry, you
    // may need to tweek REPOSITORY 
    REPOSITORY = "${DOCKER_HUB_USR}/anchorectl-test"
    TAG = "build-${BUILD_NUMBER}"
    PASSTAG = "main"
    //
  } // end environment
  agent any
  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      } // end steps
    } // end stage "checkout scm"
    
    stage('Install and Verify Tools') {
      steps {
        sh """
          ### install syft (for local SPDX/CycloneDX sbom generation, this will be implemented directly in anchorctl in the future as well)
          curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b $HOME/.local/bin v0.63.0
          ### install anchorectl 
          curl -sSfL  https://anchorectl-releases.anchore.io/anchorectl/install.sh  | sh -s -- -b $HOME/.local/bin v1.3.0
          export PATH="$HOME/.local/bin/:$PATH"
          ### now make sure it all works
          which syft
          which anchorectl
          which docker
          """
        archiveArtifacts artifacts: 'env.txt'
      } // end steps
    } // end stage "Verify Tools"
    
    
    stage('Build Image') {
      steps {
        script {
          // build image and record repo/tag in DOCKER_IMAGE
          // then push it to docker hub (or whatever registry)
          //
          sh """
            echo "${DOCKER_HUB_PSW}" | docker login ${REGISTRY} -u ${DOCKER_HUB_USR} --password-stdin
            docker build -t ${REGISTRY}/${REPOSITORY}:${TAG} --pull -f ./Dockerfile .
            # we don't need to push since we're using anchorectl, but if you wanted to you could do this:
            docker push ${REGISTRY}/${REPOSITORY}:${TAG}
          """
          // I don't like using the docker plugin but if you want to use it, here ya go
          // DOCKER_IMAGE = docker.build REPOSITORY + ":" + TAG
          // docker.withRegistry( '', HUB_CREDENTIAL ) { 
          //  DOCKER_IMAGE.push() 
          // }
        } // end script
      } // end steps
    } // end stage "Build Image"
    
    stage('Analyze Image w/ anchorectl') {
      steps {
        script {
          // first, create the local json SBOM to be archived, then
          // analyze with anchorectl and upload sbom to anchore enterprise
          sh """
            #### we installed anchorectl locally, PATH gets reset in each stage
            export PATH="$HOME/.local/bin/:$PATH"
            anchorectl image add --wait --no-auto-subscribe --force --dockerfile ./Dockerfile ${REGISTRY}/${REPOSITORY}:${TAG}
            ###
            ### alternatively you can use syft to generate the sbom locally and push the sbom to the Anchore Enterprise API:
            #
            #  syft -o json packages ${REGISTRY}/${REPOSITORY}:${TAG} | anchorectl image add --wait --dockerfile ./Dockerfile ${REGISTRY}/${REPOSITORY}:${TAG} --from -
            #
            ### note in this case you don't need to push the image first
            ###
          """
          // 
          // (note - at this point the image has not been pushed anywhere)
          //
          // we use "--wait" to wait for analysis to complete (even though we generated the sbom locally, 
          // the backend analyzer still has some work to do - it validates the uploaded sbom and inserts it into 
          // the catalog, plus it will do an initial policy evaluation etc.
          // 
          // now let's get the evaluation
          //
          try {
            sh """
              export PATH="$HOME/.local/bin/:$PATH"
              ### remove "--fail-based-on-results" if you don't care about the pass/fail policy evaulation
              anchorectl image check --fail-based-on-results ${REGISTRY}/${REPOSITORY}:${TAG}
            """
            // if you want the FULL details of the policy evaluation (which can be quite long), use "image check --detail" instead
            //
          } catch (err) {
            // if evaluation fails, clean up (delete the image) and fail the build
            sh """
              docker rmi ${REGISTRY}/${REPOSITORY}:${TAG}
              # optional: grab the evaluation with the anchore plugin so we can archive it
              # echo ${REGISTRY}/${REPOSITORY}:${TAG} > anchore_images
              # this doesn't actually work if we didn't push the image and the 
              # plug-in automatically does an "image add" which fails.
              exit 1
            """
            // anchore name: 'anchore_images'
          } // end try
        } // end script 
      } // end steps
    } // end stage "analyze with anchorectl"
    
    // THIS STAGE IS OPTIONAL
    // the purpose of this stage is to simply show that if an image passes the scan we could
    // continue the pipeline with something like "promoting" the image to production etc
    stage('Promote to Prod and Push to Registry') {
      steps {
        script {
          // login to docker hub, re-tag image as ${PASSTAG} and then push to docker hub
          // then we EITHER:
          // 1. use anchorectl to add the PASSTAG tag to the catalog - no need to wait for evaluation
          // 2. use anchore plugin to add the PASSTAG tag and grab the evaluation report
          sh """
            echo "${DOCKER_HUB_PSW}" | docker login ${REGISTRY} -u ${DOCKER_HUB_USR} --password-stdin
            docker tag ${REGISTRY}/${REPOSITORY}:${TAG} ${REPOSITORY}:${PASSTAG}
            docker push ${REGISTRY}/${REPOSITORY}:${PASSTAG}
            echo ${REGISTRY}/${REPOSITORY}:${PASSTAG} > anchore_images
            """
          anchore name: 'anchore_images'
        } // end script
      } // end steps
    } // end stage "Promote to Prod"
    
    //
    // optional stage, if you actually want to archive this stuff
    //
    stage('Clean Up') {
      // archive the sbom and delete the images locally
      steps {
        // if you want to archive artifacts uncomment this
        //archiveArtifacts artifacts: '*.json'
        sh 'docker rmi ${REGISTRY}/${REPOSITORY}:${TAG} ${REGISTRY}/${REPOSITORY}:${PASSTAG} || failure=1' 
        //
        // the "|| failure=1" at the end of this line just catches problems with the :prod
        // tag not existing if we didn't uncomment the optional "re-tag as prod" stage
        //
      } // end steps
    } // end stage "clean up"
    
  } // end stages
} // end pipeline

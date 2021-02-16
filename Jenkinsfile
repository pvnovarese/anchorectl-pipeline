// requires syft https://github.com/anchore/syft
// version 0.12.6 or higher
// requires anchore engine or anchore enterprise 
//
pipeline {
  environment {
    // don't think we really need registry if using docker hub
    // registry = 'registry.hub.docker.com'
    //
    // first let's set the docker hub credential and extract user/pass
    // we'll use the USR part for figuring out where are repository is
    //
    HUB_CREDENTIAL = "docker-hub"
    DOCKER_HUB = credentials("${HUB_CREDENTIAL}")
    //
    // we'll need the anchore credential to pass the user
    // and password to syft so it can upload the results
    //
    ANCHORE_CREDENTIAL = "AnchoreJenkinsUser"
    ANCHORE = credentials("${ANCHORE_CREDENTIAL}")
    //
    // api endpoint of your anchore instance
    ANCHORE_URL = "http://anchore-priv.novarese.net:8228/v1"
    //
    // assuming you want to use docker hub, this shouldn't need
    // any changes, but if you're using another registry, you
    // may need to tweek REPOSITORY 
    //
    REPOSITORY = "${DOCKER_HUB_USR}/anchore-pipeline-scanning"
    TAG = ":devbuild-${BUILD_NUMBER}"    
    //
    // don't need an IMAGELINE if we're not using the anchore plugin
    // IMAGELINE = "${REPOSITORY}${TAG} Dockerfile"
  }
  agent any
  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      }
    }
    stage('Build image and tag as dev') {
      steps {
        sh 'docker --version'
        script {
          // since we're using hub, we can just leave the first argument ''
          // if you're using a different registry, you'll need to add that
          // 
          docker.withRegistry( '', HUB_CREDENTIAL) {
            def DOCKER_IMAGE = docker.build(REPOSITORY + TAG)
          }
        }
      }
    }
    stage('Analyze with syft and send report to Anchore') {
      steps {
        // run syft, use jq to get the list of artifact names, concatenate 
        // output to a single line and test that curl isn't in that line
        // the grep will fail if curl exists, causing the pipeline to fail
        //
        // NOTE: I have syft installed in /var/jenkins_home because I run jenkins
        // in a container and that's the only volume I bind mount, you can put it
        // wherever you want, just fix this path.
        //
        // sh '/var/jenkins_home/syft -o json ${repository}:latest | jq .artifacts[].name | tr "\n" " " | grep -qv curl'
        withCredentials([usernamePassword(credentialsId: ANCHORE_CREDENTIAL, usernameVariable: 'ANCHORE_USER', passwordVariable: 'ANCHORE_PASS')]) {
          sh '/var/jenkins_home/syft ${REPOSITORY}${TAG} -H ${ANCHORE_URL} -u ${ANCHORE_USER} -p ${ANCHORE_PASS}'
        }      
      }
    }
    stage('Re-tag as prod and push to registry') {
      steps {
        script {
          docker.withRegistry('', HUB_CREDENTIAL) {
            DOCKER_IMAGE.push('prod') 
            // DOCKER_IMAGE.push takes the argument as a new tag for the image before pushing          
          }
        }
      }
    }
  }
}

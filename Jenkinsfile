//https://akomljen.com/set-up-a-jenkins-ci-cd-pipeline-with-kubernetes/
//https://github.com/eldada/jenkins-pipeline-kubernetes/blob/master/Jenkinsfile
// def label = "podBuild-${UUID.randomUUID().toString()}"
def label = "pod_Build_${BUILD_NUMBER}"
podTemplate(label: label, containers: [

  containerTemplate(name: 'docker', image: 'docker:latest', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'helm', image: 'lachlanevenson/k8s-helm:latest', command: 'cat', ttyEnabled: true)
],
volumes: [
  hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
 
]) {
  node(label) {

    def VERSION = "0.1.0"
    def PACKAGE = "opentaxii"
    def ARTIFACTORY_URL = "artifactory.app.eiq.sh"
 
    stage('Create packages') {
      container('docker') {
        sh "apk add --update make"
        
        def repo = git url: "https://github.com/eclecticiq/opentaxii-k8s.git", branch: 'master', credentialsId: 'f886c899-82f1-4f2f-9837-d50d4fa423c7'
        def branch = repo.GIT_BRANCH 
        stash name: "git-source"
        
        echo "Branch is: ${branch}"
        //sh "make build-packages IMAGE_TAG=${VERSION} VERSION=${VERSION} ITERATION=1"
        //archiveArtifacts(artifacts: 'dist/*', fingerprint: true)
      }
    }
    stage('Docker image') {
      withCredentials([usernamePassword(credentialsId: '63b8cd21-edfc-4ba0-ba4d-f733b625bb68', 
        passwordVariable: 'password', 
        usernameVariable: 'username')]) {
        container('docker') {
          sh """
            docker login -u ${username} -p ${password} ${ARTIFACTORY_URL}
            docker build -t artifactory.app.eiq.sh/docker/eiq-opentaxii:ci_${VERSION} .
            docker push ${ARTIFACTORY_URL}/docker/eiq-opentaxii:ci_${VERSION}
          """
        }
      }
    }
    stage ('Helm chart')  {

      withCredentials([usernamePassword(credentialsId: '63b8cd21-edfc-4ba0-ba4d-f733b625bb68', 
        passwordVariable: 'password', 
        usernameVariable: 'username')]) {
        container('helm') {
          
          unstash "git-source"
          sh "apk add --update curl"
         
          sh """
            helm init
            helm repo update
            helm repo add helm https://${ARTIFACTORY_URL}/artifactory/helm --username ${username} --password ${password}
            cd helm/opentaxii ; helm template -f Chart.yaml -f values.yaml .
            pwd ; helm package --version ${VERSION} .
            curl -u${username}:${password} -T ${PACKAGE}-${VERSION}.tgz https://${ARTIFACTORY_URL}/artifactory/helm/${PACKAGE}-${VERSION}.tgz
          """
        }
      }
    }
    stage ('Deploy chart on k8s'){
      container ('helm'){
        sh " cd helm/opentaxii ; helm upgrade --install   --name ${PACKAGE}-release ./${PACKAGE}-${VERSION}.tgz" 
      }
    }

  }//node
}

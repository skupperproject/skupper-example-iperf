# Testing network throughput across clusters

This tutorial demonstrates how to perform real-time network throughput measurements on an application router network using the iperf3 tool.

In this tutorial, you will deploy iperf3 servers in separate clusters. You will also create an application router network, which will enable the iperf3 instances to run in client mode and access peer iperf3 servers running on the different clusters (e.g. private and public).

To complete this tutorial, do the following:

* [Prerequisites](#prerequisites)
* [Step 1: Set up the demo](#step-1-set-up-the-demo)
* [Step 2: Deploy Application Router Network](#step-2-deploy-application-router-network)
* [Step 3: Deploy the iperf3 servers](#step-3-deploy-the-iperf3-servers)
* [Step 4: Run benchmark tests across the clusters](#step-4-run-benchmark-tests-across-the-clusters)
* [Next steps](#next-steps)

## Prerequisites

You should have access to three OpenShift clusters:
* A "private cloud" cluster running on your local machine
* Two public cloud clusters running in public cloud providers

For each cluster, you will need the following information:

* Cluster Name (example: "mycluster1")
* Cluster Domain (example: "devcluster.openshift.com")

## Step 1: Set up the demo

1. On your local machine, make a directory for this tutorial and clone the following repos into it:

   ```bash
   $ mkdir iperf-demo
   $ cd iperf-demo
   $ git clone git@github.com:skupperproject/skupper-example-iperf.git # for deploying the iperf3 servers
   $ wget https://github.com/skupperproject/skupper-cli/releases/download/dummy3/linux.tgz -O - | tar -xzf - # cli for application router network
   ```

2. Prepare the OpenShift clusters.

   1. Log in to each OpenShift cluster in a separate terminal session. You should have one cluster running locally on your machine, and two clusters running in public cloud providers.
   2. In each cluster, create a namespace for this demo.
  
      ```bash
      $ oc new-project iperf-demo
      ```

## Step 2: Deploy Application Router Network

On each cluster, define the application router role and connectivity to peer clusters.

1. In the terminal for the first public cluster, deploy the *public1* application router, and create its secrets:

   ```bash
   $ ~/iperf-demo/skupper init --id public1
   $ ~/iperf-demo/skupper secret ~/iperf-demo/private1-to-public1-secret.yaml -i private1
   $ ~/iperf-demo/skupper secret ~/iperf-demo/public2-to-public1-secret.yaml -i public2
   ```

2. In the terminal for the second public cluster, deploy the *public2* application router, create its secrets and define its connections to the peer *public1* cluster:

   ```bash
   $ ~/iperf-demo/skupper init --id public2
   $ ~/iperf-demo/skupper secret ~/iperf-demo/private1-to-public2-secret.yaml -i private1
   $ ~/iperf-demo/skupper connect ~/iperf-demo/public2-to-public1-secret.yaml --name public1
   ```

3. In the terminal for the private cluster, deploy the *on-prem* application router and define its connections to the public clusters

   ```bash
   $ ~/iperf-demo/skupper init --edge --id private1
   $ ~/iperf-demo/skupper connect ~/iperf-demo/private1-to-public1-secret.yaml --name public1
   $ ~/iperf-demo/skupper connect ~/iperf-demo/private1-to-public2-secret.yaml --name public2
   ```

## Step 4: Deploy the iperf3 servers

After creating the application router network, you deploy the three iperf3 servers to each of the clusters.

TODO: create a project/namespace, same as topology deployment

1. In the terminal for the private cloud, deploy the first iperf3 server:

   ```bash
   $ oc apply -f ~/iperf-demo/skupper-example-network-iperf/deployment-iperf3-a.yaml
   ```

2. In the terminal for the first public cloud, deploy the second iperf3 server:

   ```bash
   $ oc apply -f ~/iperf-demo/skupper-example-network-iperf/deployment-iperf3-b.yaml
   ```

3. In the terminal for the second public cloud, deploy the third iperf3 server:

   ```bash
   $ oc apply -f ~/iperf-demo/skupper-example-network-iperf/deployment-iperf3-c.yaml
   ```

## Step 5: Run benchmark tests across the clusters

After deploying the iperf3 servers into the private and public cloud clusters, the application router network connects the servers and enables communications even though they are running in separate clusters.

1. In the terminal for the private cloud, run the iperf3 client benchmark against each server:

   ```bash
   $ iperf3 -c  $(oc get service iperf3-svc-a -o=jsonpath='{.spec.clusterIP}')
   $ iperf3 -c  $(oc get service iperf3-svc-b -o=jsonpath='{.spec.clusterIP}')
   $ iperf3 -c  $(oc get service iperf3-svc-c -o=jsonpath='{.spec.clusterIP}')   
   ```

2. In the terminal for the first public cloud, attach to the iperf3 server container running in the cluster and run the iperf3 client benchmark against each server:

   ```bash
   $ oc exec -it $(oc get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(oc get service iperf3-svc-a -o=jsonpath='{.spec.clusterIP}')
   $ oc exec -it $(oc get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(oc get service iperf3-svc-b -o=jsonpath='{.spec.clusterIP}')
   $ oc exec -it $(oc get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(oc get service iperf3-svc-c -o=jsonpath='{.spec.clusterIP}')   
   ```

3. In the terminal for the second public cloud, attach to the iperf3 server container running in the cluster and run the iperf3 client benchmark against each server:

   ```bash
   $ oc exec -it $(oc get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(oc get service iperf3-svc-a -o=jsonpath='{.spec.clusterIP}')
   $ oc exec -it $(oc get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(oc get service iperf3-svc-b -o=jsonpath='{.spec.clusterIP}')
   $ oc exec -it $(oc get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(oc get service iperf3-svc-c -o=jsonpath='{.spec.clusterIP}')   
   ```

## Next steps

TODO: describe what the user should do after completing this tutorial

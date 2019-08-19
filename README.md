# Testing network throughput across clusters

This tutorial demonstrates how to perform real-time network throughput measurements on an application router network using the iperf3 tool.

In this tutorial, you will deploy iperf3 servers in separate clusters. You will also create an application router network, which will enable the iperf3 instances to run in client mode and access peer iperf3 servers running on the different clusters (e.g. private and public).

To complete this tutorial, do the following:

* [Prerequisites](#prerequisites)
* [Step 1: Set up the demo](#step-1-set-up-the-demo)
* [Step 2: Define Cluster Topology Values](#step-2-define-cluster-topology-values)
* [Step 3: Generate Cluster Network Files](#step-3-generate-cluster-network-files)
* [Step 4: Deploy Application Router Network](#step-4-deploy-application-router-network)
* [Step 5: Deploy the iperf3 servers](#step-5-deploy-the-iperf3-servers)
* [Step 6: Run benchmark tests across the clusters](#step-6-run-benchmark-tests-across-the-clusters)
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
   $ mkdir network-iperf-demo
   $ cd network-iperf-demo
   $ git clone git@github.com:skupperproject/skoot.git # for creating the application router network
   $ git clone git@github.com:skupperproject/skupper-example-network-iperf.git # for deploying the iperf3 servers
   ```

2. Prepare the OpenShift clusters.

   1. Log in to each OpenShift cluster in a separate terminal session. You should have one cluster running locally on your machine, and two clusters running in public cloud providers.
   2. In each cluster, create a namespace for this demo.
  
      ```bash
      $ oc new-project network-iperf-demo
      ```

## Step 2: Define Cluster Topology Values

Define the values for the application router network topology by setting up the required
environment variables. Presently, the example deployments can support up to three public
clusters and up to three private clusters.The following depicts an example deployment for
two public clusters and one private cluster:

   ```bash
   $ export SKUPPER_PUBLIC_CLUSTER_COUNT=2
   $ export SKUPPER_PRIVATE_CLUSTER_COUNT=1
   $ export SKUPPER_NAMESPACE="mongodb-replica-demo"
   $ export SKUPPER_PUBLIC_CLUSTER_SUFFIX_1="mycluster1.devcluster.openshift.com"
   $ export SKUPPER_PUBLIC_CLUSTER_SUFFIX_2="mycluster2.devcluster.openshift.com"
   $ export SKUPPER_PUBLIC_CLUSTER_NAME_1="us-east"
   $ export SKUPPER_PUBLIC_CLUSTER_NAME_2="us-west"
   $ export SKUPPER_PRIVATE_CLUSTER_NAME_1="on-prem"
   ```

## Step 3: Generate Cluster Network Files

To generate the deployment yaml files for the defined topology, execute the following:

   ```bash
   $ ~/network-iperf-demo/skoot/scripts/arn.sh | docker run -i quay.io/skupper/skoot | tar --extract
   ```

## Step 4: Deploy Application Router Network

Log in to each cluster, create the common namespace from above and deploy the corresponding yaml file.

1. In the terminal for the private cloud, deploy the application router:

   ```bash
   $ oc apply -f ~/network-iperf-demo/yaml/on-prem.yaml
   ```
2. In the terminal for the first public cloud, deploy the application router:

   ```bash
   $ oc apply -f ~/network-iperf-demo/yaml/us-east.yaml
   ```
3. In the terminal for the second public cloud, deploy the application router:

   ```bash
   $ oc apply -f ~/network-iperf-demo/yaml/us-west.yaml
   ```

## Step 5: Deploy the iperf3 servers

After creating the application router network, you deploy the three iperf3 servers to each of the clusters.

The `demos/network-iperf` directory contains the YAML files that you will use to create the servers. Each YAML file describes the set of Kubernetes resources needed to create an iperf3 server and connect it to the application router network.

TODO: create a project/namespace, same as topology deployment

1. In the terminal for the private cloud, deploy the first iperf3 server:

   ```bash
   $ oc apply -f ~/network-iperf-demo/skupper-example-network-iperf/deployment-iperf3-a.yaml
   ```

2. In the terminal for the first public cloud, deploy the second iperf3 server:

   ```bash
   $ oc apply -f ~/network-iperf-demo/skupper-example-network-iperf/deployment-iperf3-b.yaml
   ```

3. In the terminal for the second public cloud, deploy the third iperf3 server:

   ```bash
   $ oc apply -f ~/network-iperf-demo/skupper-example-network-iperf/deployment-iperf3-c.yaml
   ```

## Step 6: Run benchmark tests across the clusters

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

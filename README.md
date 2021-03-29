# Testing network throughput across clusters

This tutorial demonstrates how to perform real-time network throughput measurements on a Virtual Application Network using the iperf3 tool.

In this tutorial you will:

* deploy iperf3 servers in three separate clusters
* use the iperf3 server pods to run iperf3 client test instances
* create a Virtual Application Network which will enable the iperf3 client test instances to access iperf3 servers in any cluster

To complete this tutorial, do the following:

* [Prerequisites](#prerequisites)
* [Step 1: Set up the demo](#step-1-set-up-the-demo)
* [Step 2: Deploy the Virtual Application Network](#step-2-deploy-the-virtual-application-network)
* [Step 3: Deploy the iperf3 servers](#step-3-deploy-the-iperf3-servers)
* [Step 4: Create Skupper services for the Virtual Application Network](#step-4-create-skupper-services-for-the-virtual-application-network)
* [Step 5: Bind the Skupper services to the deployment targets on the Virtual Application Network](#step-5-bind-the-skupper-services-to-the-deployment-targets-on-the-virtual-application-network)
* [Step 6: Run benchmark tests across the clusters](#step-6-run-benchmark-tests-across-the-clusters)
* [Cleaning up](#cleaning-up)
* [Next steps](#next-steps)

## Prerequisites

* The `kubectl` command-line tool, version 1.15 or later ([installation guide](https://kubernetes.io/docs/tasks/tools/install-kubectl/))
* The `skupper` command-line tool, version 0.5 or later ([installation guide](https://skupper.io/start/index.html#step-1-install-the-skupper-command-line-tool-in-your-environment))

The basis for this demonstration is to test communication performance across distributed clusters. You should have access to three independent clusters to observe performance over a Skupper Network. As an example, the three clusters might be composed of:

* A private cloud cluster running on your local machine (**private1**)
* Two public cloud clusters running in public cloud providers (**public1** and **public2**)


## Step 1: Set up the demo

1. On your local machine, make a directory for this tutorial and clone the example repo into it:

   ```bash
   mkdir ~/iperf-demo
   cd ~/iperf-demo
   git clone https://github.com/skupperproject/skupper-example-iperf.git
   ```

2. Prepare the target clusters.

   1. On your local machine, log in to each cluster in a separate terminal session.
   2. In each cluster, create a namespace to use for the demo.
   3. In each cluster, set the kubectl config context to use the demo namespace [(see kubectl cheat sheet)](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## Step 2: Deploy the Virtual Application Network

On each cluster, using the `skupper` tool, define the Virtual Application Network and the connectivity for the peer clusters.

1. In the terminal for the first public cluster, deploy the **public1** application router. Create a connection token for connections from the **public2** cluster and the **private1** cluster:

   ```bash
   skupper init --site-name public1
   skupper token create private1-to-public1-token.yaml
   skupper token create public2-to-public1-token.yaml
   ```

2. In the terminal for the second public cluster, deploy the **public2** application router. Create a connection token for connections from the **private1** cluser and connect to the **public1** cluster:

   ```bash
   skupper init --site-name public2
   skupper token create private1-to-public2-token.yaml
   skupper link create public2-to-public1-token.yaml
   ```

3. In the terminal for the private cluster, deploy the **private1** application router. Connect to the **public1** and **public2** clusters;

   ```bash
   skupper init --site-name private1
   skupper link create private1-to-public1-token.yaml
   skupper link create private1-to-public2-token.yaml
   ```

## Step 3: Deploy the iperf3 servers

After creating the application router network, deploy one iperf3 server to each of the clusters.

1. In the terminal for the **private1** cluster, deploy the first iperf3 server:

   ```bash
   kubectl apply -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-a.yaml
   ```

2. In the terminal for the **public1** cluster, deploy the second iperf3 server:

   ```bash
   kubectl apply -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-b.yaml
   ```

3. In the terminal for the **public2** cluster, deploy the third iperf3 server:

   ```bash
   kubectl apply -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-c.yaml
   ```


## Step 4: Create Skupper services for the Virtual Application Network


1. In the terminal for the **private1** cluster, create the iperf3-server-a service:

   ```bash
   skupper service create iperf3-server-a 5201
   ```

2. In the terminal for the **public1** cluster, create the iperf3-server-b service:

   ```bash
   skupper service create iperf3-server-b 5201
   ```

3. In the terminal for the **public2** cluster, create the iperf3-server-c service:

   ```bash
   skupper service create iperf3-server-c 5201
   ```

4. In each of the cluster terminals, verify that the services are present:

   ```bash
   skupper service status
   ```

    Note that each cluster depicts the target it provides.


## Step 5: Bind the Skupper services to the deployment targets on the Virtual Application Network

1. In the terminal for the **private1** cluster, expose the iperf3-server-a deployment:

   ```bash
   skupper service bind iperf3-server-a deployment iperf3-server-a
   ```

2. In the terminal for the **public1** cluster, annotate the iperf3-server-b deployment:

   ```bash
   skupper service bind iperf3-server-b deployment iperf3-server-b
   ```

3. In the terminal for the **public2** cluster, annotate the iperf3-server-c deployment:

   ```bash
   skupper service bind iperf3-server-c deployment iperf3-server-c
   ```

4. In each of the cluster terminals, verify the services bind to the targets

   ```bash
   skupper service status
   ```

    Note that each cluster depicts the target it provides.


## Step 6: Run benchmark tests across the clusters

After deploying the iperf3 servers into the private and public cloud clusters, the application router network connects the servers and enables communications even though they are running in separate clusters.

1. In the terminal for the **private1** cluster, attach to the iperf3-server-a container running in the **private1** cluster and run the iperf3 client benchmark against each server:

   ```bash
   kubectl exec $(kubectl get pod -l application=iperf3-server-a -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-a
   kubectl exec $(kubectl get pod -l application=iperf3-server-a -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-b
   kubectl exec $(kubectl get pod -l application=iperf3-server-a -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-c
   ```

2. In the terminal for the **public1** cluster, attach to the iperf3-server-b container running in the **public1** cluster and run the iperf3 client benchmark against each server:

   ```bash
   kubectl exec $(kubectl get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-a
   kubectl exec $(kubectl get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-b
   kubectl exec $(kubectl get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-c
   ```

3. In the terminal for the **public2** cluster, attach to the iperf3-server-c container running in the **public2** cluster and run the iperf3 client benchmark against each server:

   ```bash
   kubectl exec $(kubectl get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-a
   kubectl exec $(kubectl get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-b
   kubectl exec $(kubectl get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-c
   ```


## Cleaning Up

Restore your cluster environment by returning the resources created in the demonstration and delete the skupper network:

1. In the terminal for the **private1** cluster, delete the resources:

   ```bash
   kubectl unexpose deployment iperf3-server-a
   kubectl delete -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-a.yaml
   skupper delete
   ```

2. In the terminal for the **public1** cluster, delete the resources:

   ```bash
   kubectl unexpose deployment iperf3-server-b
   kubectl delete -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-b.yaml
   skupper delete
   ```

3. In the terminal for the **public2** cluster, delete the resources:

   ```bash
   kubectl unexpose deployment iperf3-server-c
   kubectl delete -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-c.yaml
   skupper delete
   ```

## Next Steps

 - [Find more examples](https://skupper.io/examples/)

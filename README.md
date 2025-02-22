# Deployment Documentation for `cd12355-microservices-aws-kubernetes-project-starter`

This document outlines how to deploy, update, and maintain the `cd12355-microservices-aws-kubernetes-project-starter` application. It covers the tools and technologies in use and provides guidance for developers on how to release new changes to the app.

## Technologies and Tools

### 1. **Kubernetes (K8s)**
   - Kubernetes handles the deployment and management of services in a cloud environment. It automates scaling, self-healing, and monitoring of the application, ensuring everything runs smoothly.
   - We manage everything using Kubernetes resources like **Deployments**, **Services**, and **ConfigMaps** to make sure our app stays up and running and updates smoothly.

### 2. **Docker**
   - Docker containers package the app and all its dependencies, so we can be sure it will work the same in any environment, whether it's local, test, or production.
   - Docker images are built from **Dockerfiles** and stored in **Amazon ECR** (Elastic Container Registry) for easy versioning and access.

### 3. **AWS EKS (Elastic Kubernetes Service)**
   - We’re running everything on **AWS EKS**, which makes it easy to manage our Kubernetes clusters in the cloud. AWS also provides an **Elastic Load Balancer (ELB)** to handle incoming traffic and direct it to the right pods.

### 4. **CI/CD Pipeline (Optional)**
   - Although this document covers manual deployment, you can set up a **CI/CD pipeline** (like Jenkins or GitLab CI) to automate the process of building, testing, and deploying changes. This way, new commits to the repo can automatically trigger deployments to AWS.

## Deployment Process

### 1. **Build and Push Docker Images**
   - **Step 1:** Make the necessary code or configuration changes.
   - **Step 2:** Build the Docker image for each service (e.g., `coworking`, `postgres`) with:
     ```bash
     docker build -t <aws_account_id>.dkr.ecr.<region>.amazonaws.com/my-app-repo:<version_tag> .
     docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/my-app-repo:<version_tag>
     ```
   - **Step 3:** Push the image to **Amazon ECR** to store it.

### 2. **Update Kubernetes Resources**
   - **Step 1:** Once the image is in ECR, update the Kubernetes deployment YAML to use the new version of the image.
   - **Step 2:** Apply the updated YAML to the cluster:
     ```bash
     kubectl apply -f deployment.yaml
     ```
   - **Step 3:** If any config or secrets need updating, modify the **ConfigMap** or **Secrets** and apply them similarly.

### 3. **Release New Builds**
   - **Step 1:** Update the `version_tag` in the Kubernetes YAML to point to the new image version.
   - **Step 2:** Apply the changes:
     ```bash
     kubectl apply -f coworking.yaml
     ```
   - **Step 3:** Kubernetes will handle the deployment, rolling out the new version of the service. You can monitor the pods to ensure everything is running fine:
     ```bash
     kubectl get pods
     kubectl logs <pod_name>
     ```

### 4. **Database Updates**
   - **Step 1:** If you're making changes to the database schema, make sure to apply any migrations or update data manually if necessary.
   - **Step 2:** The app connects to **PostgreSQL** via environment variables (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`), which are configured in Kubernetes.

### 5. **Rollback to a Previous Version (if needed)**
   - **Step 1:** If something goes wrong, you can roll back by updating the `version_tag` in the YAML file to the previous image version.
   - **Step 2:** Apply the rollback:
     ```bash
     kubectl apply -f coworking.yaml
     ```
   - **Step 3:** Check the status of the pods and logs to confirm the rollback was successful.

### 6. **Monitoring the Application**
   - **Step 1:** You can use the following commands to check the status of your pods and their logs:
     ```bash
     kubectl get pods
     kubectl describe pod <pod_name>
     kubectl logs <pod_name> --previous
     ```
   - **Step 2:** Kubernetes health checks (liveness and readiness probes) are used to detect and resolve any issues automatically.

## Key Kubernetes Resources

1. **ConfigMap: `coworking-config`**
   - Stores application configuration, like database connection details, which can be easily updated without changing code.

2. **Secret: `coworking-secret`**
   - Stores sensitive data like database credentials. Kubernetes ensures these values are securely handled.

3. **Service: `coworking`**
   - The LoadBalancer service that makes the `coworking` app accessible externally.

4. **Deployment: `coworking`**
   - Manages the app's lifecycle, ensuring the correct number of pods are running and handling rolling updates when a new version is deployed.

## Stand Out Suggestions

1. **Specify reasonable Memory and CPU allocation in the Kubernetes deployment configuration**  
   It's a good practice to specify **CPU and memory** requests and limits for each pod in your deployment configuration. This ensures that each pod gets the necessary resources and helps Kubernetes distribute resources effectively across the cluster.

2. **In your README, specify what AWS instance type would be best used for the application? Why?**  
   For this setup, a **t3.medium** EC2 instance is a good choice for the Kubernetes worker nodes. It strikes a balance between cost and performance, offering 2 vCPUs and 4GB of RAM. For more demanding workloads, you could consider **t3.large** instances.

3. **In your README, provide your thoughts on how we can save on costs?**  
   To save on AWS costs, consider using **Spot Instances** for your Kubernetes worker nodes. Spot Instances can significantly reduce the cost of EC2 instances, especially for non-critical workloads. Also, make sure you're properly sizing your pods with CPU and memory requests, as over-provisioning can lead to wasted resources and higher costs.

## Conclusion

This document gives you a high-level overview of how to deploy, manage, and update the `cd12355-microservices-aws-kubernetes-project-starter` application in AWS EKS using Docker and Kubernetes. With these steps, you can release new versions of the app, monitor performance, and roll back changes if needed. Just follow the instructions, and you'll be able to handle deployments like a pro!


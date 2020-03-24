# Copyright 2020 Darkbit.io
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

title 'Evaluate EKS Cluster Configuration Best Practices'

awsregion = attribute('awsregion')
clustername = attribute('clustername')

control 'eks-1' do
  impact 0.9
  title 'Ensure the AWS EKS Cluster is running the latest version'

  desc "EKS clusters should be running the latest stable version to take advantage of the latest features, stability, and performance fixes.  EKS version 1.12 will be deprecated on May 11th, 2020, and version 1.12 will no longer be available for new cluster creation."
  desc "remediation", "The Kubernetes node version should ideally be identical to the control plane version, but it can trail by up to two minor versions.  This commonly happens during the process of upgrades.  If the latest available version is 1.15, and the current cluster is running 1.14 on the control plane and 1.13 nodes, the upgrade process is as follows: First, upgrade the 1.13 nodes to 1.14.  Once the nodes are healthy, upgrade the control plane to 1.15.  After the control plane is running 1.15, upgrade the nodes to match.

Considerations: EKS does not modify any of your Kubernetes add-ons for you during updates.  Be sure to upgrade the versions of the Amazon VPC CNI plugin, DNS (CoreDNS), and KubeProxy in lock-step with the supported Kubernetes versions as per the EKS Cluster Upgrade guidance.  Upgrades of node pools should proceed one node at a time, but during that process, pods will be evicted from nodes and rescheduled/restarted on other nodes up to two times.  Ensure that your applications are configured to have at least two replicas and a pod disruption budget to make sure at least one is running at all times to avoid outages during upgrades.  Also, verify that there is enough cluster workload capacity to handle a single node being removed from the cluster at any given time."
  desc "validation", "To determine the current version of your cluster, run `kubectl version --short`.  The server version should be equivalent to the latest available EKS version."

  tag platform: "AWS"
  tag category: "Management and Governance"
  tag resource: "EKS"
  tag effort: 0.5

  ref "EKS Upgrades", url: "https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html"
  ref "EKS Versions", url: "https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html"

  describe "#{awsregion}/#{clustername}: version" do
    subject { aws_eks_cluster(cluster_name: clustername, aws_region: awsregion)}
    its('major_version') { should be >= "1" }
    its('minor_version') { should be >= "15" }
  end
end

control 'eks-2' do
  impact 1.0
  title 'Ensure the AWS EKS Cluster control plane has audit logs enabled'

  desc "Amazon EKS control plane logging provides audit and diagnostic logs directly from the Amazon EKS control plane to CloudWatch Logs in your account.  By default, cluster control plane logs aren't sent to CloudWatch Logs. You must enable each log type individually to send logs for your cluster. CloudWatch Logs ingestion, archive storage, and data scanning rates apply to enabled control plane logs.  The following cluster control plane log types are available: 

* Kubernetes API server component logs (api) – Your cluster's API server is the control plane component that exposes the Kubernetes API.
* Audit (audit) – Kubernetes audit logs provide a record of the individual users, administrators, or system components that have affected your cluster.
* Authenticator (authenticator) – Authenticator logs are unique to Amazon EKS. These logs represent the control plane component that Amazon EKS uses for Kubernetes Role Based Access Control (RBAC) authentication using IAM credentials.
* Controller manager (controllerManager) – The controller manager manages the core control loops that are shipped with Kubernetes.
* Scheduler (scheduler) – The scheduler component manages when and where to run pods in your cluster."
  desc "remediation", "To update the current EKS cluster configuration to add logging to CloudWatch, run `aws eks --region <region> update-cluster-config --name <clustername> --logging '{'clusterLogging':[{'types':['api','audit','authenticator','controllerManager','scheduler'],'enabled':true}]}'`.  The configuration of the cluster will take several minutes to complete."
  desc "validation", "To determine the current control plane logging configuration, run `aws eks describe-cluster` and review the `clusterLogging` types that are `enabled`.  All should be listed as `enabled` and none should be listed as `disabled`."

  tag platform: "AWS"
  tag category: "Management and Governance"
  tag resource: "EKS"
  tag effort: 0.2

  ref "EKS Control Plane Logging", url: "https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html"

  describe "#{awsregion}/#{clustername}: audit logs" do
    subject { aws_eks_cluster(cluster_name: clustername, aws_region: awsregion)}
    its('logs_enabled') { should cmp ["api", "audit", "authenticator", "controllerManager", "scheduler"] }
  end
end

control 'eks-3' do
  impact 0.9
  title 'Ensure the AWS EKS Cluster is not public'

  desc "Amazon EKS creates an endpoint for the managed Kubernetes API server that you use to communicate with your cluster using kubectl, for example. By default, this API server endpoint is public to the internet, and access to the API server is secured using a combination of AWS Identity and Access Management (IAM), native Kubernetes Role Based Access Control (RBAC), and an access control list that allows any IP address (0.0.0.0/0) to connect.  While this makes administration convenient, the scope of potential attackers is not limited should a newly discovered vulnerability or denial-of-service become available.  Also, should valid credentials from a phished administrator/developer be stolen or leaked, they can be directly used without having to originate from a known set of IP ranges."
  desc "remediation", "During cluster creation, specify `endpointPrivateAccess=true` in the `resourcesVpcConfig` block.  Or, specify `publicAccessCidrs` to be a set of CIDR ranges that do not include `0.0.0.0/0`.  For existing clusters, `publicAccessCidrs` can be updated using `aws eks update-cluster-config` under the `--resources-vpc-config` flag."
  desc "validation", "Run `aws eks describe-cluster` and review the contents of the `resourcesVpcConfig` block.  `endpointPrivateAccess` should be `true`.  Or, if `endpointPublicAccess` is `true`, `publicAccessCidrs` should be set to something other than `0.0.0.0/0`."

  tag platform: "AWS"
  tag category: "Network Access Control"
  tag resource: "EKS"
  tag effort: 0.5

  ref "EKS Cluster Endpoint Access Control", url: "https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html"
  ref "EKS VPC Considerations", url: "https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html"

  describe "#{awsregion}/#{clustername}: public setting" do
    subject { aws_eks_cluster(cluster_name: clustername, aws_region: awsregion)}
    it { should_not be_public }
  end
end

control 'eks-4' do
  impact 0.3
  title 'Ensure the AWS EKS Cluster has application secrets encryption enabled'

  desc "Envelope encryption for secrets is available for new Amazon EKS clusters running Kubernetes version 1.13 and above. You can setup your own Customer Master Key (CMK) in KMS and link this key by providing the CMK ARN when you create an EKS cluster. When secrets are stored using the Kubernetes secrets API, they are encrypted with a Kubernetes-generated data encryption key, which is then further encrypted using the linked AWS KMS key."
  desc "remediation", "Configure a Customer Master Key (CMK) in KMS, and during cluster creation, configure the `--encryption-config` option to specify the ARN of the KMS key."
  desc "validation", "Run `aws eks describe-cluster` and look for the presence of the `encryptionConfig` block."

  tag platform: "AWS"
  tag category: "Secrets Management"
  tag resource: "EKS"
  tag effort: 0.5

  ref "EKS Application Secrets Encryption", url: "https://aws.amazon.com/about-aws/whats-new/2020/03/amazon-eks-adds-envelope-encryption-for-secrets-with-aws-kms/"
  ref "EKS Create Cluster", url: "https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html"

  describe "#{awsregion}/#{clustername}: application secrets encryption" do
    subject { aws_eks_cluster(cluster_name: clustername, aws_region: awsregion)}
    it { should have_encryption_enabled }
  end
end

control 'eks-5' do
  impact 0.3
  title 'Ensure AWS EKS Cluster Subnets are available, non-default, and not automatically mapping public IPs'

  desc "In order to help maintain proper separation from other workloads in the account and to ensure there are enough IPs available for nodes and pods, AWS EKS clusters should be deployed into new Subnets created specifically for the cluster."
  desc "remediation", "Create new, dedicated subnets.  The recommended guidance is at least two public and two private subnets.  Redeploy the EKS cluster with these subnets configured."
  desc "validation", "Run `aws eks describe-cluster` to get the list of `subnetIds` under the `resourcesVpcConfig` block.  For each subnet, run `aws ec2 describe-subnets` and validate that `default-for-az` is `false` and that `mapPublicIpOnLaunch` is also `false`."

  tag platform: "AWS"
  tag category: "Network Access Control"
  tag resource: "EKS"
  tag effort: 1.0

  ref "EKS VPC Considerations", url: "https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html"

  aws_eks_cluster(cluster_name: clustername, aws_region: awsregion).subnets.each do |subnet|
    describe "#{awsregion}/#{clustername}/#{subnet}: subnets" do
      subject { aws_subnet(subnet_id: subnet, aws_region: awsregion)}
      it { should be_available }
      it { should_not be_default_for_az }
      it { should_not be_mapping_public_ip_on_launch }
    end
  end
end

control 'eks-6' do
  impact 0.5
  title 'Ensure AWS EKS Cluster Nodegroups do not allow remote access from all IPs'

  desc "During EKS Nodegroup creation, remote access via SSH to the nodes can optionally be configured.  If enabled, it should not specify a security group that permits inbound access on TCP/22 from `0.0.0.0/0`.  Instead, it should be a known set of CIDR ranges used for administrative purposes.  Without this restriction, attackers that can escape pods to become root on a node may be able to add their credentials and SSH directly to the node from any IP."
  desc "remediation", "Identify the security group associated with the nodegroup for remote access, and modify the rules to remove `0.0.0.0/0` from the source ranges.  Replace it with one or more CIDR ranges used for administration."
  desc "validation", "Run `aws eks describe-nodegroup` and find the `remoteAccess` > `sourceSecurityGroups`.  Use `aws ec2 describe-security-groups` and review the `IpPermissions` for the presence of `0.0.0.0/0`."

  tag platform: "AWS"
  tag category: "Network Access Control"
  tag resource: "EKS"
  tag effort: 0.3

  ref "EKS Nodegroups", url: "https://docs.aws.amazon.com/eks/latest/userguide/create-managed-node-group.html"

  aws_eks_nodegroups(cluster_name: clustername, aws_region: awsregion).names.each do |nodegroup|
    describe "#{awsregion}/#{clustername}/#{nodegroup}: nodegroup" do
      subject { aws_eks_nodegroup(cluster_name: clustername, aws_region: awsregion, nodegroup_name: nodegroup)}
      it { should have_remote_access_source_security_groups }
    end
    aws_eks_nodegroup(cluster_name: clustername, aws_region: awsregion, nodegroup_name: nodegroup).remote_access_source_security_groups.each do |sg|
      describe "#{awsregion}/#{clustername}/#{nodegroup}/#{sg}: remote access source security group" do
        subject { aws_security_group(group_id: sg, aws_region: awsregion) }
        it { should_not allow_in(ipv4_range: "0.0.0.0/0", port: 22) }
      end
    end
  end
end

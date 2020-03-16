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

title 'Test a collection of AWS EKS Clusters'

awsregion = attribute('awsregion')
clustername = attribute('clustername')

control 'eks-1' do
  impact 0.0
  title 'Ensure AWS EKS Clusters are at the latest version'

  desc "default", "EKS clusters should be the latest version"
  desc "remediation", "Upgrade the EKS cluster"

  tag domain: "01. Identity and Access Management"
  tag platform: "AWS"
  tag category: "Identity and Access Management"
  tag resource: "EKS"
  tag effort: 0.2

  ref "ref1", url: "https://ref1.local"

  describe "#{awsregion}/#{clustername}: " do
    subject { aws_eks_cluster(cluster_name: clustername, aws_region: awsregion)}
    its('version') { should cmp "1.15" }
  end
end

control 'eks-2' do
  impact 0.0
  title 'Ensure AWS EKS Clusters are not public'

  desc "default", "EKS clusters should not have publicly available control planes"
  desc "remediation", "Recreate the EKS cluster with a private control plane"

  tag domain: "01. Identity and Access Management"
  tag platform: "AWS"
  tag category: "Identity and Access Management"
  tag resource: "EKS"
  tag effort: 0.2

  ref "ref1", url: "https://ref1.local"

  describe "#{awsregion}/#{clustername}: public setting " do
    subject { aws_eks_cluster(cluster_name: clustername, aws_region: awsregion)}
    it { should_not be_public }
  end
end

control 'eks-3' do
  impact 0.0
  title 'Ensure AWS EKS Clusters have audit logs enabled'

  desc "default", "EKS clusters should not have publicly available control planes"
  desc "remediation", "Recreate the EKS cluster with a private control plane"

  tag domain: "01. Identity and Access Management"
  tag platform: "AWS"
  tag category: "Identity and Access Management"
  tag resource: "EKS"
  tag effort: 0.2

  ref "ref1", url: "https://ref1.local"

  describe "#{awsregion}/#{clustername}: audit logs" do
    subject { aws_eks_cluster(cluster_name: clustername, aws_region: awsregion)}
    its('logs_enabled') { should cmp ["api", "audit", "authenticator", "controllerManager", "scheduler"] }
  end
end

control 'eks-4' do
  impact 0.0
  title 'Ensure AWS EKS Clusters has application secrets encryption'

  desc "default", "EKS clusters should not have publicly available control planes"
  desc "remediation", "Recreate the EKS cluster with a private control plane"

  tag domain: "01. Identity and Access Management"
  tag platform: "AWS"
  tag category: "Identity and Access Management"
  tag resource: "EKS"
  tag effort: 0.2

  ref "ref1", url: "https://ref1.local"

  describe "#{awsregion}/#{clustername}: application secrets encryption" do
    subject { aws_eks_cluster(cluster_name: clustername, aws_region: awsregion)}
    it { should have_encryption_enabled }
  end
end

control 'eks-5' do
  impact 0.0
  title 'Ensure AWS EKS Cluster Subnets are available and not the default'

  desc "default", "EKS clusters should not have publicly available control planes"
  desc "remediation", "Recreate the EKS cluster with a private control plane"

  tag domain: "01. Identity and Access Management"
  tag platform: "AWS"
  tag category: "Identity and Access Management"
  tag resource: "EKS"
  tag effort: 0.2

  ref "ref1", url: "https://ref1.local"

  aws_eks_cluster(cluster_name: clustername, aws_region: awsregion).subnets.each do |subnet|
    describe "#{awsregion}/#{clustername}/#{subnet}: subnets" do
      subject { aws_subnet(subnet_id: subnet, aws_region: awsregion)}
      it { should be_available }
      it { should_not be_default_for_az }
    end
  end
end

control 'eks-6' do
  impact 0.0
  title 'Ensure AWS EKS Cluster Subnets do not automatically provide public IPs'

  desc "default", "EKS clusters should not have publicly available control planes"
  desc "remediation", "Recreate the EKS cluster with a private control plane"

  tag domain: "01. Identity and Access Management"
  tag platform: "AWS"
  tag category: "Identity and Access Management"
  tag resource: "EKS"
  tag effort: 0.2

  ref "ref1", url: "https://ref1.local"

  aws_eks_cluster(cluster_name: clustername, aws_region: awsregion).subnets.each do |subnet|
    describe "#{awsregion}/#{clustername}/#{subnet}: subnets" do
      subject { aws_subnet(subnet_id: subnet, aws_region: awsregion)}
      it { should_not be_mapping_public_ip_on_launch }
    end
  end
end

control 'eks-7' do
  impact 0.0
  title 'Ensure AWS EKS Cluster Nodegroups are healthy'

  desc "default", "EKS clusters should have healthy nodegroups"
  desc "remediation", "Ensure nodegroups are healthy and active"

  tag domain: "01. Identity and Access Management"
  tag platform: "AWS"
  tag category: "Identity and Access Management"
  tag resource: "EKS"
  tag effort: 0.2

  ref "ref1", url: "https://ref1.local"

  aws_eks_nodegroups(cluster_name: clustername, aws_region: awsregion).names.each do |nodegroup|
    describe "#{awsregion}/#{clustername}/#{nodegroup}: nodegroup" do
      subject { aws_eks_nodegroup(cluster_name: clustername, aws_region: awsregion, nodegroup_name: nodegroup)}
      it { should be_healthy }
      it { should be_active }
    end
  end
end

control 'eks-8' do
  impact 0.0
  title 'Ensure AWS EKS Cluster Nodegroups have autoscaling configured'

  desc "default", "EKS clusters should nodegroups with autoscaling enabled"
  desc "remediation", "Configure the nodegroups to enable autoscaling"

  tag domain: "01. Identity and Access Management"
  tag platform: "AWS"
  tag category: "Identity and Access Management"
  tag resource: "EKS"
  tag effort: 0.2

  ref "ref1", url: "https://ref1.local"

  aws_eks_nodegroups(cluster_name: clustername, aws_region: awsregion).names.each do |nodegroup|
    describe "#{awsregion}/#{clustername}/#{nodegroup}: nodegroup" do
      subject { aws_eks_nodegroup(cluster_name: clustername, aws_region: awsregion, nodegroup_name: nodegroup)}
      it { should have_autoscaling_enabled }
    end
  end
end

control 'eks-9' do
  impact 0.0
  title 'Ensure AWS EKS Cluster Nodegroups do not allow remote access'

  desc "default", "EKS clusters should not have nodegroups with remote access"
  desc "remediation", "Disable remote access to nodegroups"

  tag domain: "01. Identity and Access Management"
  tag platform: "AWS"
  tag category: "Identity and Access Management"
  tag resource: "EKS"
  tag effort: 0.2

  ref "ref1", url: "https://ref1.local"

  aws_eks_nodegroups(cluster_name: clustername, aws_region: awsregion).names.each do |nodegroup|
    describe "#{awsregion}/#{clustername}/#{nodegroup}: nodegroup" do
      subject { aws_eks_nodegroup(cluster_name: clustername, aws_region: awsregion, nodegroup_name: nodegroup)}
      it { should_not have_remote_access_enabled }
    end
  end
end

# frozen_string_literal: true

require 'aws_backend'

class AwsEksNodegroups < AwsResourceBase
  name 'aws_eks_nodegroups'
  desc 'Verifies settings for a collection AWS EKS Node Pools'
  example '
    describe aws_eks_nodegroups do
      it { should exist }
    end
  '

  attr_reader :table, :cluster_name, :aws_region

  FilterTable.create
             .register_column(:names,                   field: :name)
             .register_column(:arns,                    field: :arn)
             .register_column(:cluster_names,           field: :cluster_name)
             .register_column(:versions,                field: :version)
             .register_column(:release_versions,        field: :release_version)
             .register_column(:statuses,                field: :status)
             .register_column(:ami_types,               field: :ami_type)
             .install_filter_methods_on_resource(self, :table)

  def initialize(opts = {})
    super(opts)
    validate_parameters(allow: [:cluster_name, :aws_region])
    @cluster_name = opts[:cluster_name] || "none" 
    @aws_region = opts[:aws_region] || "us-east-1" 
    @table = fetch_data
  end

  def fetch_data
    nodegroup_rows = []
    pagination_options = {}
    catch_aws_errors do
      response = @aws.eks_client.list_nodegroups(cluster_name: @cluster_name)
      return [] if !response || response.empty?
      response.nodegroups.each do |nodegroup_name|
        nodegroup = @aws.eks_client.describe_nodegroup(cluster_name: @cluster_name, nodegroup_name: nodegroup_name).nodegroup
        nodegroup_rows += [{ 
                           name:                  nodegroup.nodegroup_name,
                           arn:                   nodegroup.nodegroup_arn,
                           cluster_name:          nodegroup.cluster_name,
                           version:               nodegroup.version,
                           release_version:       nodegroup.release_version,
                           status:                nodegroup.status,
                           ami_type:              nodegroup.ami_type
                        }]
      end
    end
    @table = nodegroup_rows
  end
end

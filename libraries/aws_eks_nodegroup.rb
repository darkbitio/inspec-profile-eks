# frozen_string_literal: true

require 'aws_backend'

class AwsEksNodegroup < AwsResourceBase
  name 'aws_eks_nodegroup'
  desc 'Verifies settings for an EKS Nodegroup'

  example "
    describe aws_eks_nodegroup(cluster_name: 'mycluster', nodegroup_name: 'mynodegroup') do
      it { should exist }
    end
  "

  attr_reader :name, :status, :arn, :cluster_name, :version, :release_version, :created_at,
              :tags, :labels, :node_role, :ami_type, :instance_types, :disk_size, :subnets,
              :issues, :autoscaling_group_name, :remote_access_security_group, :ssh_key,
              :autoscaling_min, :autoscaling_max, :autoscaling_desired, :resp,
              :remote_access_source_security_groups

  def initialize(opts = {})
    super(opts)
    validate_parameters(required: [:cluster_name, :nodegroup_name])
    catch_aws_errors do
      @resp = @aws.eks_client.describe_nodegroup(cluster_name: opts[:cluster_name], nodegroup_name: opts[:nodegroup_name]).nodegroup
      @name                         = resp[:nodegroup_name]
      @arn                          = resp[:nodegroup_arn]
      @node_role                    = resp[:node_role]
      @cluster_name                 = resp[:cluster_name]
      @version                      = resp[:version]
      @release_version              = resp[:release_version]
      @created_at                   = resp[:created_at]
      @status                       = resp[:status]
      @tags                         = resp[:tags]
      @labels                       = resp[:labels]
      @ami_type                     = resp[:ami_type]
      @instance_types               = resp[:instance_types]
      @disk_size                    = resp[:disk_size]
      @subnets                      = resp[:subnets]
      @issues                       = resp[:health][:issues]
      @autoscaling_min              = resp[:scaling_config][:min_size] || 0
      @autoscaling_max              = resp[:scaling_config][:max_size] || 0
      @autoscaling_desired          = resp[:scaling_config][:desired_size] || 0
      @autoscaling_group_name       = resp[:resources][:auto_scaling_groups][0][:name] || ""
      @remote_access_security_group = resp[:resources][:remote_access_security_group] || ""
      @ssh_key                      = resp[:remote_access].nil? ? "" : resp[:remote_access][:ec2_ssh_key] || ""
      @remote_access_source_security_groups = resp[:remote_access].nil? ? [] : resp[:remote_access][:source_security_groups] || [@remote_access_security_group]
    end
  end

  def has_autoscaling_enabled? 
    @autoscaling_max > @autoscaling_min
  end

  def has_remote_access_source_security_groups?
    if !@remote_access_source_security_groups.nil?
      return true
    end
    return false
  end

  def active?
    @status == "ACTIVE"
  end

  def healthy?
    @issues.empty? && @status == "ACTIVE"
  end

  def exists?
    @arn.start_with?('arn:')
  end

  def to_s
    "AWS EKS Nodegroup #{@cluster_name}/#{@name}"
  end
end

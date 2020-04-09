# frozen_string_literal: true

require 'aws_backend'

class AwsEksCluster < AwsResourceBase
  name 'aws_eks_cluster'
  desc 'Verifies settings for an EKS cluster'

  example "
    describe aws_eks_cluster('cluster-name') do
      it { should exist }
    end
  "

  attr_reader :version, :arn, :certificate_authority, :name,
              :status, :endpoint, :subnets_count, :subnet_ids, :security_group_ids,
              :created_at, :role_arn, :vpc_id, :security_groups_count, :creating,
              :active, :failed, :deleting, :tags, :created_at, 
              :cluster_security_group_id, :endpoint_public_access, :endpoint_private_access,
              :public_access_cidrs, :logging, :identity, :platform_version, :full_name,
              :encryption_enabled, :major_version, :minor_version

  def initialize(opts = {})
    opts = { cluster_name: opts } if opts.is_a?(String)
    super(opts)
    validate_parameters(required: [:cluster_name])

    catch_aws_errors do
      resp = @aws.eks_client.describe_cluster(name: opts[:cluster_name]).cluster
      @arn                   = resp[:arn]
      @version               = resp[:version]
      @major_version         = resp[:version].split(".").first
      @minor_version         = resp[:version].split(".").last
      @platform_version      = resp[:platform_version]
      @certificate_authority = resp[:certificate_authority][:data]
      @name                  = resp[:name]
      @full_name             = "#{opts[:aws_region]}/#{resp[:name]}"
      @created_at            = resp[:created_at]
      @status                = resp[:status]
      @endpoint              = resp[:endpoint]
      @subnet_ids            = resp[:resources_vpc_config][:subnet_ids]
      @subnets_count         = resp[:resources_vpc_config][:subnet_ids].length
      @security_group_ids    = resp[:resources_vpc_config][:security_group_ids]
      @security_groups_count = resp[:resources_vpc_config][:security_group_ids].length
      @cluster_security_group_id = resp[:resources_vpc_config][:cluster_security_group_id]
      @endpoint_public_access = resp[:resources_vpc_config][:endpoint_public_access]
      @endpoint_private_access = resp[:resources_vpc_config][:endpoint_private_access]
      @public_access_cidrs   = resp[:resources_vpc_config][:public_access_cidrs]
      @vpc_id                = resp[:resources_vpc_config][:vpc_id]
      @encryption_config     = resp[:encryption_config] || nil
      @logging               = resp[:logging]
      @identity              = resp[:identity]
      @created_at            = resp[:created_at]
      @role_arn              = resp[:role_arn]
      @active                = resp[:status] == 'ACTIVE'
      @failed                = resp[:status] == 'FAILED'
      @creating              = resp[:status] == 'CREATING'
      @deleting              = resp[:status] == 'DELETING'
      @tags                  = resp[:tags]
    end
  end

  def subnets
    @subnet_ids
  end

  def has_encryption_enabled?
    return false if @encryption_config.nil?
    @encryption_config.each do |config|
      return true if config.resources.include?("secrets")
    end
    return false
  end

  def logs_enabled
    @logging[:cluster_logging].each do |logging|
      next if logging[:enabled].nil?
      next unless logging[:enabled]
      return logging[:types].sort
    end
    return [] 
  end

  def logs_disabled
    @logging[:cluster_logging].each do |logging|
      next if logging[:enabled].nil?
      next if logging[:enabled]
      return logging[:types].sort
    end
    return [] 
  end

  def public?
    return false if @endpoint_private_access
    return true if @endpoint_public_access || @public_access_cidrs.include?('0.0.0.0/0')
    return false
  end

  def exists?
    @arn.start_with?('arn:')
  end

  def to_s
    "AWS EKS Cluster #{@full_name}"
  end
end

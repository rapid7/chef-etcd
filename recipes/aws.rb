cookbook_version = run_context.cookbook_collection[cookbook_name].metadata.version
Chef::Log.info("Building an insstance of #{ cookbook_name }@#{ cookbook_version }")
aws_resource_tag node['ec2']['instance_id'] do
  tags :Name => "#{ cookbook_name }-#{ cookbook_version }",
       :Service => cookbook_name,
       :Version => cookbook_version,
       :Stack => node.stack
  action :update
  not_if { node.baking? }
end if node.ec2?

require 'puppet_x/intechwifi/logical'
require 'puppet_x/intechwifi/declare_environment_resources'

Puppet::Functions.create_function('define_environment_resources') do
  def define_environment_resources(
    name,
    status,     # cannot use 'ensure' as it is a reserved word in ruby.
    region,
    network,
    zones,
    server_roles,
    services,
    db_servers,
    s3,
    tags,
    resource_type_tags,
    policies,
    label_formats,
    pg_sites,
    domains,
    lambdas,
    sns_topics,
    s3_event_notifications,
    options
  )
    PuppetX::IntechWIFI::DeclareEnvironmentResources.define_environment_resources(
        name,
        status,
        region,
        network,
        zones,
        server_roles,
        services,
        db_servers,
        s3,
        tags,
        resource_type_tags,
        policies,
        label_formats,
        pg_sites,
        domains,
        lambdas,
        sns_topics,
        s3_event_notifications,
        options
    )
  end
end


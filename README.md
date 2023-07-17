# ecs-proxy

Proxy connections from a PrivateLink NLB to a set of a ECS services

## Components

<ol type="1">
  <li>VPC - dependency</li>
    <ol type="a">
      <li>Subnets</li>
      <li>Security groups</li>
      <li>Letter C</li>
    </ol>
  <li>NLB</li>
    <ol type="a">
      <li>Listeners</li>
    </ol>
  <li>ECS services</li>
    <ol type="a">
      <li>Instances</li>
      <li>Cluster</li>
      <li>Services</li>
    </ol>  
</ol>

## Provisioning

```
terraform init
terraform apply
```

## Testing

```
terraform output -json | jq -r 'to_entries[] | .key + "=" + (.value.value | tostring)' | while read -r line ; do echo export "$line"; done > outputs.sh
source outputs.sh
echo "The DNS name of the ALB is $nlb_dns_name"
echo "The first ECS Service is listening on port $first_service_port"
 ```

You'll have to wait for the Target groups to settle. I created a script for this. Run it like so:

```
./scripts/wait_for_target_group.sh $first_service_target_group_arn
./scripts/wait_for_target_group.sh $second_service_target_group_arn
```

Once you've got targets for the NLB you can run the following commands to test them out:

```
curl http://$nlb_dns_name:$first_service_port
curl http://$nlb_dns_name:$second_service_port
```

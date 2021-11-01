import boto3

ecs = boto3.client('ecs', region_name='us-east-1')
ec2 = boto3.client('ec2', region_name='us-east-1')

rc = ecs.list_clusters()

for cluster in rc['clusterArns']:
    ci = ecs.list_container_instances(cluster=cluster)

    if len(ci['containerInstanceArns']) > 0:
        r2 = ecs.describe_container_instances(
            cluster=cluster,
            containerInstances=ci['containerInstanceArns'])

        ids = [x['ec2InstanceId'] for x in r2['containerInstances']]

        r3 = ec2.describe_instances(InstanceIds=ids)

        for r in r3['Reservations']:
            for i in r['Instances']:
                print("{0}: instance {1}, state {2}, AMI {3}, private IP {4}, public IP {5}".format(
                    cluster.split('/')[-1],
                    i['InstanceId'],
                    i['State']['Name'],
                    i['ImageId'],
                    i['PrivateIpAddress'] if 'PrivateIpAddress' in i else 'n/a',
                    i['PublicIpAddress'] if 'PublicIpAddress' in i else 'n/a'))
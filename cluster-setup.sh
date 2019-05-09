#!/bin/sh
aws --version
#aws ec2 describe-vpcs
#aws ec2 describe-subnets
#aws ec2 describe-security-groups

echo "creating iam role"
echo "creating vpc and subnet"
aws cloudformation create-stack --stack-name eks-Cap --template-body file:///home/ubuntu/amazon-eks-vpc-sample.yaml --parameters ParameterKey=VpcBlock,ParameterValue=192.168.0.0/16 ParameterKey=Subnet01Block,ParameterValue=192.168.64.0/18 ParameterKey=Subnet02Block,ParameterValue=192.168.128.0/18 ParameterKey=Subnet03Block,ParameterValue=192.168.192.0/18
sleep 100
echo "displaying the subnets and vpc created"
vpcvalue=`aws ec2 describe-vpcs --filters Name=tag:Name,Values=eks-Cap-VPC | grep "VpcId" | cut -d ":" -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
subnet01value=`aws ec2 describe-subnets --filters Name=tag:Name,Values=eks-Cap-Subnet01 | grep "SubnetId" | cut -d ":" -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
subnet02value=`aws ec2 describe-subnets --filters Name=tag:Name,Values=eks-Cap-Subnet02 | grep "SubnetId" | cut -d ":" -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
subnet03value=`aws ec2 describe-subnets --filters Name=tag:Name,Values=eks-Cap-Subnet03 | grep "SubnetId" | cut -d ":" -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
securitygrpvalue=`aws ec2 describe-security-groups --filters Name=tag:aws:cloudformation:stack-name,Values=eks-Cap | grep "GroupId" | cut -d ":" -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
echo $vpcvalue
echo $subnet01value
echo $subnet02value
echo $subnet03value
echo $securitygrpvalue
echo "create eks cluster"
aws eks --region us-east-2 create-cluster --name eks-Cap --role-arn arn:aws:iam::828164643967:role/eksCluster-cap --resources-vpc-config subnetIds=$subnet01value,$subnet02value,$subnet03value,securityGroupIds=$securitygrpvalue
sleep 650
echo "cluster status"
aws eks --region us-east-2 describe-cluster --name eks-Cap --query cluster.status
aws eks --region us-east-2 update-kubeconfig --name eks-Cap
kubectl get svc
echo "create nodes for the cluster"
aws cloudformation create-stack --stack-name eks-Cap-nodes  --template-body file:///home/ubuntu/amazon-eks-nodegroup.yaml --parameters ParameterKey=ClusterName,ParameterValue=eks-Cap ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=$securitygrpvalue ParameterKey=NodeGroupName,ParameterValue=eks-Cap-nodes ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=1 ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue=3 ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=4 ParameterKey=NodeInstanceType,ParameterValue=t3.medium ParameterKey=NodeImageId,ParameterValue=ami-04ea7cb66af82ae4a ParameterKey=KeyName,ParameterValue=cap-nagaraju ParameterKey=VpcId,ParameterValue=$vpcvalue ParameterKey=Subnets,ParameterValue=\"$subnet01value,$subnet02value,$subnet03value\" --capabilities CAPABILITY_IAM
aws cloudformation describe-stack --stack-name eks-Cap-nodes
sleep 200
echo "adding workers to cluster"
#curl -O https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-01-09/aws-auth-cm.yaml
#kubectl apply -f aws-auth-cm.yaml
                                         

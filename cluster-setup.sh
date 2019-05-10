#!/bin/sh
Workers=$1
reg=$2
Size=$3
Cluster_Name=$4
aws --version
#aws ec2 describe-vpcs
#aws ec2 describe-subnets
#aws ec2 describe-security-groups
echo "number of workers to be created $Workers"
echo "region selected $reg"
echo "size of instance selected $Size"
aws configure set region $reg
bash image.sh $reg > test
image=`cat test`
echo $image
echo "inserting values in cfn template"
sed -i '115d' amazon-eks-nodegroup.yaml
sed -i "115i\\    Default: $Workers" amazon-eks-nodegroup.yaml

sed -i '18d' amazon-eks-nodegroup.yaml
sed -i "18i\\    Default: $Size" amazon-eks-nodegroup.yaml
#echo "creating iam role"
echo "creating vpc and subnet"
aws cloudformation create-stack --stack-name $Cluster_Name --template-body file:///home/ubuntu/amazon-eks-vpc-sample.yaml --parameters ParameterKey=VpcBlock,ParameterValue=192.168.0.0/16 ParameterKey=Subnet01Block,ParameterValue=192.168.64.0/18 ParameterKey=Subnet02Block,ParameterValue=192.168.128.0/18 ParameterKey=Subnet03Block,ParameterValue=192.168.192.0/18
sleep 100
echo "displaying the subnets and vpc created"
vpcvalue=`aws ec2 describe-vpcs --filters Name=tag:Name,Values=$Cluster_Name-VPC | grep "VpcId" | cut -d ":" -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
subnet01value=`aws ec2 describe-subnets --filters Name=tag:Name,Values=$Cluster_Name-Subnet01 | grep "SubnetId" | cut -d ":" -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
subnet02value=`aws ec2 describe-subnets --filters Name=tag:Name,Values=$Cluster_Name-Subnet02 | grep "SubnetId" | cut -d ":" -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
subnet03value=`aws ec2 describe-subnets --filters Name=tag:Name,Values=$Cluster_Name-Subnet03 | grep "SubnetId" | cut -d ":" -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
securitygrpvalue=`aws ec2 describe-security-groups --filters Name=tag:aws:cloudformation:stack-name,Values=$Cluster_Name | grep "GroupId" | cut -d ":" -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
echo $vpcvalue
echo $subnet01value
echo $subnet02value
echo $subnet03value
echo $securitygrpvalue
echo "create eks cluster"
aws eks --region $reg create-cluster --name $Cluster_Name --role-arn arn:aws:iam::828164643967:role/eksCluster-cap --resources-vpc-config subnetIds=$subnet01value,$subnet02value,$subnet03value,securityGroupIds=$securitygrpvalue
sleep 650
echo "cluster status"
aws eks --region $reg describe-cluster --name $Cluster_Name --query cluster.status
aws eks --region $reg update-kubeconfig --name $Cluster_Name
kubectl get svc
echo "create nodes for the cluster"
aws cloudformation create-stack --stack-name $Cluster_Name-nodes  --template-body file:///home/ubuntu/amazon-eks-nodegroup.yaml --parameters ParameterKey=ClusterName,ParameterValue=$Cluster_Name ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=$securitygrpvalue ParameterKey=NodeGroupName,ParameterValue=$Cluster_Name-nodes ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=1 ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue=$Workers ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=4 ParameterKey=NodeInstanceType,ParameterValue=$Size ParameterKey=NodeImageId,ParameterValue=$image ParameterKey=KeyName,ParameterValue=cap-$reg ParameterKey=VpcId,ParameterValue=$vpcvalue ParameterKey=Subnets,ParameterValue=\"$subnet01value,$subnet02value,$subnet03value\" --capabilities CAPABILITY_IAM
aws cloudformation describe-stacks --stack-name $Cluster_Name-nodes
sleep 400
echo "adding workers to cluster"
iam_role=`aws iam list-roles | grep NodeInstanceRole | sed -n '2p' | cut -d '"' -f4`
echo $iam_role
sed -i '8d'  aws-auth-cm.yaml
sed -i "8i\\    - rolearn: $iam_role" aws-auth-cm.yaml
#sed -i 's/- rolearn:.*/- rolearn: '$test'/g' aws-auth-cm.yaml
kubectl delete -f aws-auth-cm.yaml
kubectl create -f aws-auth-cm.yaml
sleep 30
kubectl get nodes
kubectl version
echo "pushing to github"
cd /home/ubuntu
rm -rf eks-app-platform-config
git clone https://github.com/nagarajui7/eks-app-platform-config.git
cd eks-app-platform-config
mkdir $Cluster_Name-$Region
kubectl get nodes > /home/ubuntu/eks-app-platform-config/$Cluster_Name-$Region/worker_nodes
aws eks describe-cluster --name $Cluster_Name > /home/ubuntu/eks-app-platform-config/$Cluster_Name-$Region/cluster_info.json
cd /home/ubuntu
#cp worker_nodes /home/ubuntu/eks-app-platform-config/$Cluster_Name-$Region
#cp cluster-info.json /home/ubuntu/eks-app-platform-config/$Cluster_Name-$Region
cd eks-app-platform-config
git add .
git status
git commit -m "files"
#git push origin master
git push https://nagaraju.batchu1%40gmail.com:N%40Ga%4012345@github.com/nagarajui7/eks-app-platform-config.git

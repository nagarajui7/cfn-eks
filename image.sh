#!/bin/bash
reg=$1
if [ $reg == "us-east-1" ];
then
        image=ami-0abcb9f9190e867ab
        echo $image
elif [ $reg == "us-east-2" ];
then
        image=ami-04ea7cb66af82ae4a
        echo $image
elif [ $reg == "eu-central-1" ];
then
        image=ami-0d741ed58ca5b342e
        echo $image
elif [ $reg == "eu-west-1" ];
then
        image=ami-08716b70cac884aaa
        echo $image
else
        echo "wrong zone"
fi

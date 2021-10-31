#!/bin/bash
APP_ID=$1
CLUSTERNAME=$2
ENVIRONMENT=`echo $CLUSTERNAME | tr a-z A-Z`
PASSWORD=`kubectl get secret --namespace "kube-system" mysql-password-secret -o jsonpath="{.data.rootpassword}" | base64 --decode`
APP_HOST=$3
ITEM_KEY=$4
ITEM_VALUE=$5

while true;
do
  kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -e "show databases;" | grep Apollo > /dev/null
  [ 0 -eq $? ] && break
  sleep 30
done

itemidx=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "select Id from Namespace where NamespaceName=\"$APP_HOST\" and ClusterName=\"$CLUSTERNAME\";" | tail -n1`
itemidx=`expr $itemidx + 1`

id=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "select Id from Namespace where NamespaceName=\"$APP_HOST\" and ClusterName=\"$CLUSTERNAME\";"`
appnamespaceid=`echo $id | awk '{ print $2 }'`

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "INSERT INTO Item (NamespaceId, \`Key\`, Value, LineNum, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $appnamespaceid, \"$ITEM_KEY\", \"$ITEM_VALUE\", $itemidx, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Item WHERE NamespaceId=\"$appnamespaceid\" AND \`Key\`=\"$ITEM_KEY\");"

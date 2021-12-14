#!/bin/bash
APP_ID=$1
CLUSTERNAME=$2
ENVIRONMENT=`echo $CLUSTERNAME | tr a-z A-Z`
PASSWORD=`kubectl get secret --namespace "kube-system" mysql-password-secret -o jsonpath="{.data.rootpassword}" | base64 --decode`
APP_HOST=$3
ITEM_KEY=$4
ITEM_VALUE=$5

[ "x" == "x$ITEM_VALUE" ] && echo "ITEM_VALUE can not be null" && exit 1

while true;
do
  kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -e "show databases;" | grep Apollo > /dev/null
  [ 0 -eq $? ] && break
  sleep 30
done


id=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "select Id from Namespace where NamespaceName=\"$APP_HOST\" and ClusterName=\"$CLUSTERNAME\";"`
appnamespaceid=`echo $id | awk '{ print $2 }'`

itemidx=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "select Id from Item where NamespaceId=\"$appnamespaceid\";" | tail -n1`
itemidx=`expr $itemidx + 1`

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "DELETE FROM Item WHERE NamespaceId=\"$appnamespaceid\" AND \`Key\`=\"$ITEM_KEY\";"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "INSERT INTO Item (NamespaceId, \`Key\`, Value, LineNum, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $appnamespaceid, \"$ITEM_KEY\", \"$ITEM_VALUE\", $itemidx, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Item WHERE NamespaceId=\"$appnamespaceid\" AND \`Key\`=\"$ITEM_KEY\" AND \`Value\`=\"$ITEM_VALUE\");"

#if [[ "xdevelopment" == "x$CLUSTERNAME" || "xtesting" == "x$CLUSTERNAME" ]]; then
#  jsondata=$(kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "select NamespaceId, CONCAT('{',GROUP_CONCAT(CONCAT('\"',\`key\`, '\":\"', Value, '\"')), '}') from Item where NamespaceId=$appnamespaceid AND \`Value\`!='' group by NamespaceId;" | tail -n1 | awk '{ print $2 }')
#  echo $jsondata
#
#  name="`date +%Y%m%d%H%M%S`""-release"
#  releasekey="`date +%Y%m%d%H%M%S`""-""`cat /dev/urandom | od -x | sed 's/\s*//g' |cut -c 8-23 | head -n1`"
#
#  kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "INSERT INTO \`Release\` (ReleaseKey, Name, AppId, ClusterName, NamespaceName, Configurations) SELECT \"$releasekey\", \"$name\", \"$APP_ID\", \"$CLUSTERNAME\", \"$APP_HOST\", '$jsondata' FROM DUAL WHERE NOT EXISTS (SELECT * FROM \`Release\` WHERE ClusterName=\"$CLUSTERNAME\" AND NamespaceName=\"$APP_HOST\" AND Configurations='$jsondata');"
#fi

jsondata=$(kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "select NamespaceId, CONCAT('{',GROUP_CONCAT(CONCAT('\"',\`key\`, '\":\"', Value, '\"')), '}') from Item where NamespaceId=$appnamespaceid AND \`Value\`!='' group by NamespaceId;" | tail -n1 | awk '{ print $2 }')
echo $jsondata

name="`date +%Y%m%d%H%M%S`""-release"
releasekey="`date +%Y%m%d%H%M%S`""-""`cat /dev/urandom | od -x | sed 's/\s*//g' |cut -c 8-23 | head -n1`"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "INSERT INTO \`Release\` (ReleaseKey, Name, AppId, ClusterName, NamespaceName, Configurations) SELECT \"$releasekey\", \"$name\", \"$APP_ID\", \"$CLUSTERNAME\", \"$APP_HOST\", '$jsondata' FROM DUAL WHERE NOT EXISTS (SELECT * FROM \`Release\` WHERE ClusterName=\"$CLUSTERNAME\" AND NamespaceName=\"$APP_HOST\" AND Configurations='$jsondata');"

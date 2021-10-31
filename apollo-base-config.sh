#!/bin/bash
APP_ID=$1
CLUSTERNAME=$2
ENVIRONMENT=`echo $CLUSTERNAME | tr a-z A-Z`
MYSQL_PASSWORD=`kubectl -n kube-system get secret mysql-password-secret -o jsonpath='{.data}' | awk -F 'rootpassword":"' '{ print $2 }' | awk -F '"' '{ print $1 }'`
PASSWORD=`echo $MYSQL_PASSWORD | base64 --decode`
APP_HOST=$3

while true;
do
  kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -e "show databases;" | grep Apollo > /dev/null
  [ 0 -eq $? ] && break
  sleep 30
done

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "INSERT INTO AppNamespace (Name, AppId, Comment, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"$APP_HOST\", $APP_ID, \"$APP_HOST namespace\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM AppNamespace WHERE AppId=\"$APP_ID\" AND Name=\"$APP_HOST\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "INSERT INTO Namespace (AppId, ClusterName, NamespaceName, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $APP_ID, \"$CLUSTERNAME\", \"$APP_HOST\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Namespace WHERE AppId=\"$APP_ID\" AND ClusterName=\"$CLUSTERNAME\" and NamespaceName=\"$APP_HOST\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO AppNamespace (Name, AppId, Comment, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"$APP_HOST\", $APP_ID, \"$APP_HOST namespace\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM AppNamespace WHERE AppId=\"$APP_ID\" AND Name=\"$APP_HOST\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Permission (PermissionType, TargetId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"ModifyNamespace\", \"$APP_ID+$APP_HOST\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Permission WHERE TargetId=\"$APP_ID+$APP_HOST\" AND PermissionType=\"ModifyNamespace\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Permission (PermissionType, TargetId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"ReleaseNamespace\", \"$APP_ID+$APP_HOST\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Permission WHERE TargetId=\"$APP_ID+$APP_HOST\" AND PermissionType=\"ReleaseNamespace\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Permission (PermissionType, TargetId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"ModifyNamespace\", \"$APP_ID+$APP_HOST+$ENVIRONMENT\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Permission WHERE TargetId=\"$APP_ID+$APP_HOST+$ENVIRONMENT\" AND PermissionType=\"ModifyNamespace\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Permission (PermissionType, TargetId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"ReleaseNamespace\", \"$APP_ID+$APP_HOST+$ENVIRONMENT\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Permission WHERE TargetId=\"$APP_ID+$APP_HOST+$ENVIRONMENT\" AND PermissionType=\"ReleaseNamespace\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Role (RoleName, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"ModifyNamespace+$APP_ID+$APP_HOST\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Role WHERE RoleName=\"ModifyNamespace+$APP_ID+$APP_HOST\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Role (RoleName, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"ReleaseNamespace+$APP_ID+$APP_HOST\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Role WHERE RoleName=\"ReleaseNamespace+$APP_ID+$APP_HOST\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Role (RoleName, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"ModifyNamespace+$APP_ID+$APP_HOST+$ENVIRONMENT\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Role WHERE RoleName=\"ModifyNamespace+$APP_ID+$APP_HOST+$ENVIRONMENT\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Role (RoleName, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"ReleaseNamespace+$APP_ID+$APP_HOST+$ENVIRONMENT\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Role WHERE RoleName=\"ReleaseNamespace+$APP_ID+$APP_HOST+$ENVIRONMENT\");"

id=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "select Id from Namespace where NamespaceName=\"$APP_HOST\";"`
appnamespaceid=`echo $id | awk '{ print $2 }'`

# insert in Jenkinsfile
# kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "INSERT INTO Item (NamespaceId, \`Key\`, Value, LineNum, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $appnamespaceid, \"username\", \"root\", 1, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Item WHERE NamespaceId=\"$appnamespaceid\" AND \`Key\`=\"username\");"
# kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "INSERT INTO Item (NamespaceId, \`Key\`, Value, LineNum, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $appnamespaceid, \"password\", \"$PASSWORD\", 2, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Item WHERE NamespaceId=\"$appnamespaceid\" AND \`Key\`=\"password\");"

modifyrole=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Role where RoleName=\"ModifyNamespace+$APP_ID+$APP_HOST\";"`
modifyroleid=`echo $modifyrole | awk '{ print $2 }'`
modifyrolepermission=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Permission where PermissionType=\"ModifyNamespace\" and TargetId=\"$APP_ID+$APP_HOST\";"`
modifyrolepermissionid=`echo $modifyrolepermission | awk -F 'Id ' '{ print $2 }'`
for permissionid in $modifyrolepermissionid;do
  kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO RolePermission (RoleId, PermissionId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $modifyroleid, $permissionid, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM RolePermission WHERE RoleId=\"$modifyroleid\" AND PermissionId=\"$permissionid\");"
done
 
releaserole=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Role where RoleName=\"ReleaseNamespace+$APP_ID+$APP_HOST\";"`
releaseroleid=`echo $releaserole | awk '{ print $2 }'`
releaserolepermission=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Permission where PermissionType=\"ReleaseNamespace\" and TargetId=\"$APP_ID+$APP_HOST\";"`
releaserolepermissionid=`echo $releaserolepermission | awk -F 'Id ' '{ print $2 }'`
for permissionid in $releaserolepermissionid;do
  kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO RolePermission (RoleId, PermissionId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $releaseroleid, $permissionid, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM RolePermission WHERE RoleId=\"$releaseroleid\" AND PermissionId=\"$permissionid\");"
done

modifyrole_env=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Role where RoleName=\"ModifyNamespace+$APP_ID+$APP_HOST+$ENVIRONMENT\";"`
modifyroleid_env=`echo $modifyrole_env | awk '{ print $2 }'`
modifyrolepermission_env=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Permission where PermissionType=\"ModifyNamespace\" and TargetId=\"$APP_ID+$APP_HOST+$ENVIRONMENT\";"`
modifyrolepermissionid_env=`echo $modifyrolepermission_env | awk -F 'Id ' '{ print $2 }'`
for permissionid in $modifyrolepermissionid_env;do
  kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO RolePermission (RoleId, PermissionId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $modifyroleid_env, $permissionid, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM RolePermission WHERE RoleId=\"$modifyroleid_env\" AND PermissionId=\"$permissionid\");"
done

releaserole_env=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Role where RoleName=\"ReleaseNamespace+$APP_ID+$APP_HOST+$ENVIRONMENT\";"`
releaseroleid_env=`echo $releaserole_env | awk '{ print $2 }'`
releaserolepermission_env=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Permission where PermissionType=\"ReleaseNamespace\" and TargetId=\"$APP_ID+$APP_HOST+$ENVIRONMENT\";"`
releaserolepermissionid_env=`echo $releaserolepermission_env | awk -F 'Id ' '{ print $2 }'`
for permissionid in $releaserolepermissionid_env;do
  kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO RolePermission (RoleId, PermissionId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $releaseroleid_env, $permissionid, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM RolePermission WHERE RoleId=\"$releaseroleid_env\" AND PermissionId=\"$permissionid\");"
done

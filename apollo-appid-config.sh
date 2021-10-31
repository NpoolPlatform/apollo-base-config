#!/bin/bash
APP_ID=$1
CLUSTERNAME=$2
ENVIRONMENT=`echo $CLUSTERNAME | tr a-z A-Z`
PASSWORD=`kubectl get secret --namespace "kube-system" mysql-password-secret -o jsonpath="{.data.rootpassword}" | base64 --decode`

while true;
do
  kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -e "show databases;" | grep Apollo > /dev/null
  [ 0 -eq $? ] && break
  sleep 30
done

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "INSERT INTO App (AppId, Name, OrgId, OrgName, OwnerName, OwnerEmail,DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $APP_ID, \"test\", \"TEST1\", \"npool\", \"apollo\", \"apollo@acme.com\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM App WHERE AppId=\"$APP_ID\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloConfigDB -e "INSERT INTO Cluster (Name, AppId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"$CLUSTERNAME\", $APP_ID, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Cluster WHERE AppId="$APP_ID" AND Name=\"$CLUSTERNAME\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO App (AppId, Name, OrgId, OrgName, OwnerName, OwnerEmail,DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $APP_ID, \"test\", \"TEST1\", \"npool\", \"apollo\", \"apollo@acme.com\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM App WHERE AppId=\"$APP_ID\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Permission (PermissionType, TargetId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"CreateCluster\", $APP_ID, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Permission WHERE TargetId=\"$APP_ID\" AND PermissionType=\"CreateCluster\");"
kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Permission (PermissionType, TargetId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"CreateNamespace\", $APP_ID, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Permission WHERE TargetId=\"$APP_ID\" AND PermissionType=\"CreateNamespace\");"
kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Permission (PermissionType, TargetId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"AssignRole\", $APP_ID, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Permission WHERE TargetId=\"$APP_ID\" AND PermissionType=\"AssignRole\");"
kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Permission (PermissionType, TargetId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"ManageAppMaster\", $APP_ID, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Permission WHERE TargetId=\"$APP_ID\" AND PermissionType=\"ManageAppMaster\");"

kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Role (RoleName, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"Master+$APP_ID\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Role WHERE RoleName=\"Master+$APP_ID\");"
kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO Role (RoleName, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT \"ManageAppMaster+$APP_ID\", \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM Role WHERE RoleName=\"ManageAppMaster+$APP_ID\");"


master=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Role where RoleName=\"Master+$APP_ID\";"`
masterroleid=`echo $master | awk '{ print $2 }'`
masterpermission=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Permission where (PermissionType=\"AssignRole\" or PermissionType=\"CreateCluster\" or PermissionType=\"CreateNamespace\") and TargetId=\"$APP_ID\";"`
masterpermissionid=`echo $masterpermission | awk -F 'Id ' '{ print $2 }'`
for permissionid in $masterpermissionid;do
  kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO RolePermission (RoleId, PermissionId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $masterroleid, $permissionid, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM RolePermission WHERE RoleId=\"$masterroleid\" AND PermissionId=\"$permissionid\");"
done

manageappmaster=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Role where RoleName=\"ManageAppMaster+$APP_ID\";"`
manageroleid=`echo $manageappmaster | awk '{ print $2 }'`
managerpermission=`kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "select Id from Permission where PermissionType=\"ManageAppMaster\" and TargetId=\"$APP_ID\";"`
managerpermissionid=`echo $managerpermission | awk -F 'Id ' '{ print $2 }'`
for permissionid in $managerpermissionid;do
  kubectl -n kube-system exec mysql-0 -- mysql -h 127.0.0.1 -uroot -p$PASSWORD -P3306 -D ApolloPortalDB -e "INSERT INTO RolePermission (RoleId, PermissionId, DataChange_CreatedBy, DataChange_LastModifiedBy) SELECT $manageroleid, $permissionid, \"apollo\", \"apollo\" FROM DUAL WHERE NOT EXISTS (SELECT * FROM RolePermission WHERE RoleId=\"$manageroleid\" AND PermissionId=\"$permissionid\");"
done

# list all active ports
sudo lsof -i -P -n | grep LISTEN

# if you get docker pull error in pods then apply eval and rebuild images
eval $(minikube docker-env)

# minikube commands
minikube start
minikugbe status

# Cliam pv
kubectl apply -f persistent-volume.yml
kubectl describe pv mysql-pv-volume
kubectl describe pvc mysql-pv-claim
# As you made a hostPath type persistent volume, you can find the data by logging into the minikube node minikube ssh and navigate to the spcified path (/mnt/data).



# Create MySQL Table
# source https://kubernetes.io/docs/tasks/run-application/run-single-instance-stateful-application/
# Deploy the PV and PVC of the YAML file:
kubectl apply -f mysql-pv.yaml
# Deploy MYSQL
kubectl apply -f mysql-deployment.yaml
# Display information about the Deployment:
kubectl describe deployment mysql
# List the pods created by the Deployment:
kubectl get pods -l app=mysql
# Inspect the PersistentVolumeClaim:
kubectl describe pvc mysql-pv-claim
# Accessing the MySQL instance 
kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -ppassword
# pods options
kubectl describe pod PODNAME
kubectl get pod --watch
kubectl get pod -o wide
# Deleting a deployment
# Delete the deployed objects by name:
kubectl delete deployment,svc mysql # all at once
kubectl delete pvc mysql-pv-claim #pvc
kubectl delete pv mysql-pv-volume #pv
# delete everything from current namespace
kubectl delete all --all


# SQL
mysql -uroot -p
# Create Database and table in SQL
CREATE DATABASE flaskapi;
USE flaskapi;
CREATE TABLE users(user_id INT PRIMARY KEY AUTO_INCREMENT, user_name VARCHAR(255), user_email VARCHAR(255), user_password VARCHAR(255));



# Docker commands
docker build . -t crud-api-python
docker run -p 3306:3360 --name=oracle-sql -d mysql/mysql-server:latest
docker ps
sudo docker logs oracle-sql
sudo docker exec -it oracle-sql bash
docker run -d -p 5000:5000  --name crud-api-python anandshivam44/crud-api-python:latest
docker commit 2f4998960368 
docker push anandshivam44/crud-api-python:latest


# make sql accessible outside docker image
select host, user from mysql.user;
update mysql.user set host = '%' where user='root';

# login to mysql server. Server can be in container or host machine.
mysql -uroot -p -P3306 -h127.0.0.1

# create sql docker image and configure
create SQL docker image best tutorial https://www.youtube.com/watch?v=X8W5Xq9e2Os




# Deploy this project
# 1
kubectl get all
# 2
kubectl apply -f secret.yaml 
# 3
kubectl get secret
# 4
kubectl apply -f mysql-deployment.yaml
# 5
kubectl get all
# 6
kubectl get pods
# 7
kubectl get pod --watch
# 8
kubectl describe pod  sql-deployment-599544495d-ssmbt
# 9
kubectl logs  sql-deployment-599544495d-ssmbt
# 10
kubectl get service
# 11
kubectl describe service sql-service
# 12
kubectl get pod -o wide
# 13
kubectl get all
# 14
kubectl apply -f configmap.yaml
# 15
kubectl apply -f flaskapp-deployment.yaml
# 16
kubectl get service
# 17
minikube service [name]
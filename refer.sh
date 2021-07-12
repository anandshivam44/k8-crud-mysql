#
minikube start
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

CREATE DATABASE flaskapi;
USE flaskapi;
CREATE TABLE users(user_id INT PRIMARY KEY AUTO_INCREMENT, user_name VARCHAR(255), user_email VARCHAR(255), user_password VARCHAR(255));




flask-service


kubectl describe pod PODNAME
kubectl get pod --watch
kubectl get pod -o wide



# Deleting a deployment
# Delete the deployed objects by name:
kubectl delete deployment,svc mysql # all at once
kubectl delete pvc mysql-pv-claim 
kubectl delete pv mysql-pv-volume 

# if you get docker pull error in pods then apply eval and rebuild images
eval $(minikube docker-env)

# delete everything from current namespace
kubectl delete all --all





--------------
docker build . -t flask-api
 docker run -p 3306:3360 --name=oracle-sql -d mysql/mysql-server:latest
 
 sudo lsof -i -P -n | grep LISTEN

 docker ps
 sudo docker logs oracle-sql
 sudo docker exec -it oracle-sql bash



mysql -uroot -p

CREATE DATABASE flaskapi;
USE flaskapi;
CREATE TABLE users(user_id INT PRIMARY KEY AUTO_INCREMENT, user_name VARCHAR(255), user_email VARCHAR(255), user_password VARCHAR(255));

# make sql accessible outside docker image
select host, user from mysql.user;
update mysql.user set host = '%' where user='root';

mysql -uroot -p -P3306 -h127.0.0.1


create SQL docker image best tutorial https://www.youtube.com/watch?v=X8W5Xq9e2Os

docker run -d -p 5000:5000  --name crud-api-python anandshivam44/crud-api-python:latest

docker commit 2f4998960368 
docker push anandshivam44/crud-api-python:latest



# FROM MONGO DEPLOYMENT Example

kubectl get all

kubectl apply -f secret.yaml 

kubectl get secret

kubectl apply -f mysql-deployment.yaml

kubectl get all
kubectl get pods

kubectl get pod --watch

kubectl describe pod  sql-deployment-599544495d-ssmbt

kubectl logs  sql-deployment-599544495d-ssmbt

kubectl get service

kubectl describe service sql-service

kubectl get pod -o wide

kubectl get all

kubectl apply -f configmap.yaml

kubectl apply -f flaskapp-deployment.yml

kubectl get service

minikube service [name]



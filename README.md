# Deploying a Flask API and MySQL server on Kubernetes

Objective:
1) Build a Docker container running a CRUD Application using python and Flask 
2) Pull pre-configured sql server container from the writer's(me) dockerhub repo  
3) Deploys a MySQL server on a Kubernetes cluster
4) Attaches a persistent volume to it, so the data remains contained if pods are restarting
5) Deploys a Flask API to add, delete and modify users in the MySQL database

#### Prerequisites for host machine
 - hypervisor installed to use mimikube
 - minikube installed to start k8 cluster
 - docker installed
 - kubectl installed


### Step 0: Clone this repo
```
git clone https://github.com/anandshivam44/k8-crud-mysql.git
```
### Step 1: Build your python application into a Docker container 

Here is the content of the Dockefile. It installs necessary libraries and requirements.

Our app flaskapi.py is running on port 5000 and hence exposing port 5000
```
FROM python:3.6-slim

RUN apt-get clean \
    && apt-get -y update

RUN apt-get -y install \
    nginx \
    python3-dev \
    build-essential

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt --src /usr/local/src

COPY . .

EXPOSE 5000
CMD [ "python", "flaskapi.py" ]

```

 - Build Docker image. Replace "anandshivam44/crud-api-python:latest" with your own hub.docker.com username and container name in Step 1
```
docker build . -t anandshivam44/crud-api-python:latest
```
 - Run image
```
docker run -d -p 5000:5000  --name crud-api-python anandshivam44/crud-api-python:latest
```
 - Commit image
```
docker commit [image-id]
```
 - Push image to hub.docker.com
```
docker push anandshivam44/crud-api-python:latest
```

### Step 2: Step Pull mysql container
Pull my pre-configured mysql container from anandshivam44/mysql:latest
```
docker pull anandshivam44/mysql:latest
```
About this container. What has already been done:
 - The container user 'root' password is set to 'password'
 - The container has been provisoned to be accesses outside the container.

These two steps are already configured in this container to remove overhead, but you can always manually pull and configure your mysql server.

Run the container
```
docker container run -d -p 3306:3306 anandshivam44/mysql:latest
```
Check if the mysql server can be accesses ouside the container on the host machine
```
mysql -uroot -ppassword -P3306 -h127.0.0.1
```
You can also access the database outside on the host machine using softwares like MySQL Workbench or DBeaver Community

### Step 3: Prepare yaml files for Kubernetes Deployment
#### - secret.yaml
secret.yaml: secret.yaml contains secrets such as Database username and password. All values are base64 encoded. These values are later referred in mysql-deployment.yaml which is ultimately passes as environment variables to our crud-api-python container. Secrets should always be passed to k8 cluster before they are used in pods anywhere.

To generate base64 values use
```
echo -n 'username' | base64
echo -n 'password' | base64
```
Replace your own values with values in secret.yaml file
Add more values as per your deployment/requirement
#### - mysql-deployment.yaml
mysql-deployment.yaml contains 3 yaml document combined into 1 file because they all fall into same category i.e. they serve mysql database pod. They are 
 - Deployment: Contains config about mysql deployment itself
 - Service: Contains information about networking rules of 'Deployment' or mysql database
 - PersistentVolumeClaim: Forwards a proposal of persistent volume of 2 Gb to be claimed. This volume is later claimed by 'Deployment'. So now our database will reside in persistent storage. Even if the pod is deleted our data is still not deleted. 

#### - configmap.yaml
configmap.yaml contains configurations/ConfigMap such as database url. It passes database url to all the replica sets. It avoids manual labour of configuring hostname in Frontend Application. ConfigMap should always be executed before they are used in pods.

#### - flaskapp-deployment.yaml
flaskapp-deployment.yaml has 2 yaml documents:
 - Deployment
 - Service: contains information about networking rules of 'Deployment' or our Flask Api pod deployment
##### Additional information 
When our CRUD container/pod is run, it will try to connect to the database, If databse is not found in MySql server our python app wil create new database using
```
CREATE DATABASE flaskapi;
USE flaskapi;
CREATE TABLE users(user_id INT PRIMARY KEY AUTO_INCREMENT, user_name VARCHAR(255), user_email VARCHAR(255), user_password VARCHAR(255));
```

### Step 4: Deply your application into k8 cluster  
 - Start minikube
```
minikube start
```
 - Optional: to get everything fresh use 
```
kubectl delete all --all
```
This will clean up yoour k8 cluster
A more cleaner way of doing is
```
minikube delete
minikube start
```
 - Add all secrets
```
kubectl apply -f secret.yaml 

kubectl get secret # verify if secrets were added
```
 - Deploy your mysql databse
```

kubectl apply -f mysql-deployment.yaml

kubectl get pod --watch # watch your pod starting

kubectl describe pod  [replace with pod name] # if pod is taking too long to start describe pod to see its activity

kubectl logs [replace with pod name] # check logs to see if everything is okay inside pods

kubectl get service # check if your service for mysql is active

kubectl describe service sql-service # describe service
```
 - Deploy CRUD/python/flask pod
```
# apply ConfigMap before flask deplyment since flask deployment needs database host url from ConfigMap 
kubectl apply -f configmap.yaml

# deploy you CRUD API
kubectl apply -f flaskapp-deployment.yml
```
 - Get Service and url to access your Application
```
kubectl get service # get/observe all services

minikube service [service name] # get service url from minikube. Use this url to access your CRUD Application
```

### Step 5: How to test your deployment
 - Get a Hello World response
```
curl http://192.168.49.2:30000
```
 - Add a user to databse 
```
curl -H "Content-Type: application/json" -d '{"name": "usernamw1234", "email": "emailid@provider.com", "pwd": "Password@1234"}' http://192.168.49.2:30000/create
```

 - Get all users
```
curl http://192.168.49.2:30000/users
```
 - Get user details by index
```
curl http://192.168.49.2:30000/user/1
```
 - Delete a user by user_id: 
```
curl -H "Content-Type: application/json" -d '{"name": "<user_name>", "email": "<user_email>", "pwd": "<user_password>"}' <service_URL>/delete
```
 - Update a user's information: 
```
curl -H "Content-Type: application/json" -d {"name": "<user_name>", "email": "<user_email>", "pwd": "<user_password>", "user_id": <user_id>} <service_URL>/update
```

### Step 6: Cleaning up
Delete everything from cluster
```
kubectl delete all -all
```
or
Delete cluster, delete minikub virtual environment
```
minikube delete
```



# Deploying a Flask API and MySQL server on Kubernetes

Objective:
- [x] Build a Docker container running a CRUD [Create, Read, Edit, Delete] Application using python and Flask 
- [x] Pull pre-configured SQL server container from the writer's(me) docker hub repo  
- [x] Deploys a MySQL server on a Kubernetes cluster
- [x] Attaches a persistent volume to it, so the data remains contained if pods are restarting
- [x] Deploys a Flask API to add, delete and modify users in the MySQL database
- [ ] Automate deployment using helm. `coming soon`.

#### Prerequisites for the host machine
 - hypervisor installed to use minikube
 - minikube installed to start k8 cluster
 - docker installed
 - kubectl installed

#### tree . 
```markdown
.
├── configmap.yaml              ConfigMap to get service url
├── crud-application            
│   ├── Dockerfile              Dockerfile to build your own image
│   ├── flaskapi.py             CRUD API python application using Flask
│   └── requirements.txt        contains all libraries needed by python application
├── flaskapi-testing.py         a python crud application for testing
├── flaskapp-deployment.yml     yaml file to deploy your CRUD Application
├── helm-charts                 helm charts coming soon
├── mysql-deployment.yaml       yaml file to deploy mysql server
├── README.md                   this README file you are reading now
├── refer.sh                    a list of helpful commands
└── secret.yaml                 yaml file to store secret in k8 cluster
```
### Step 0: Getting Started
 - Clone this repo
```bash
git clone https://github.com/anandshivam44/k8-crud-mysql.git
cd k8-crud-mysql
```
 - Configure `Docker` to use the `Docker daemon` in your kubernetes cluster via your terminal: 

```bash
eval $(minikube docker-env)
```
 - Refer `refer.sh` file. It contains a list of commands that might at times be very useful
### Step 1: Build your python application into a Docker container 

Here is the content of the Dockerfile. It installs necessary libraries and requirements.

`Optional`: Prebuilt image can be found at https://hub.docker.com/repository/docker/anandshivam44/crud-api-python

Our app flaskapi.py is running on port 5000 and hence exposing port 5000
```shell
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

 - Build Docker image
TODO: Replace "anandshivam44/crud-api-python:latest" with your own https://hub.docker.com username and container name in all of Step 1
```bash
docker build . -t anandshivam44/crud-api-python:latest
```
 - Run image
```bash
docker run -d -p 5000:5000  --name crud-api-python anandshivam44/crud-api-python:latest
```
 - Commit container
```bash
docker commit [image-id]
```
 - Push the container to https://hub.docker.com
```bash
docker push anandshivam44/crud-api-python:latest
```

### Step 2: Setup and test MySQL container
 - Pull my pre-configured MySQL container from anandshivam44/mysql:latest
```bash
docker pull anandshivam44/mysql:latest
```
About this container. What has already been done:
 1) The container user 'root' password is set to 'password'
 2) The container has been provisioned to be accessed outside the container.

These two steps are already configured in this container to remove overhead, but you can always manually pull and configure your MySQL server.
Link to the container https://hub.docker.com/repository/docker/anandshivam44/mysql
 - Run the container
```bash
docker container run -d -p 3306:3306 anandshivam44/mysql:latest
```
 - Check if the MySQL server can be accessed outside the container on the host machine
```bash
mysql -uroot -ppassword -P3306 -h127.0.0.1 
```
You can also access the database outside on the host machine using software like MySQL Workbench or DBeaver Community

### Step 3: Prepare YAML files for Kubernetes Deployment
#### - secret.yaml
secret.yaml: secret.yaml contains secrets such as Database username and password. All values are base64 encoded. These values are later referred to in mysql-deployment.yaml which is ultimately passed as environment variables to our crud-api-python container. Secrets should always be passed to the k8 cluster before they are used in pods anywhere.

To generate base64 values use
```bash
echo -n 'username' | base64
echo -n 'password' | base64
```
Replace your own values with values in secret.yaml file
Add more values as per your deployment/requirement
<br/>
###### secret.yaml
```yaml

# Add secrets to secret manager
# All secrets are base64 encoded
# name 'sql-secret' will be used to refer to and point these secrets

apiVersion: v1
kind: Secret
metadata:
    name: sql-secret
type: Opaque
data:
    sql-root-username: cm9vdA==
    sql-root-password: cGFzc3dvcmQ=
    sql-root-database-name: LW0gZmxhc2thcGkK
```
#### - mysql-deployment.yaml
mysql-deployment.yaml contains 3 yaml documents combined into 1 file because they all fall into the same category i.e. they serve MySQL database pod. They are 
 1) Deployment: Contains config about MySQL deployment itself
 2) Service: Contains information about networking rules of 'Deployment' or MySQL database
 3) PersistentVolumeClaim: Forwards a proposal of the persistent volume of 2 Gb to be claimed. This volume is later claimed by 'Deployment'. So now our database will reside in persistent storage. Even if the pod is deleted our data is still not deleted. 


<br/>

###### mysql-deployment.yaml
```yaml


# Request a persistent volume
# Add name and tabg
# Set access mode policy to ReadWriteOnce
# size of persistent volume is 2 Gb

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
  labels:
    app: sql-deployment
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---

# Create a deployment for our MySQL database
# Add name and tag to it
# Set no of replicas/pods to 1
# Set container to pull from anandshivam44/mysql
# Open port 3306 of pod running MySQL
# Add sensitive environment variable from cluster secret manager. MYSQL_DATABASE_USER, MYSQL_DATABASE_PASSWORD. Since our SQL image is pre-configured we don't need it here now. In our case, env variables are set but are never used
# mount persistent volume to /var/lib/mysql
# Claim persistent volume

apiVersion: apps/v1
kind: Deployment
metadata:
  name: sql-deployment
  labels:
    app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: sql
          image: anandshivam44/mysql
          ports:
            - containerPort: 3306
          env:
            - name: MYSQL_DATABASE_USER
              valueFrom:
                secretKeyRef:
                  name: sql-secret
                  key: sql-root-username
            - name: MYSQL_DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: sql-secret
                  key: sql-root-password
          volumeMounts:
            - name: mysql-persistent-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mysql-persistent-storage
          persistentVolumeClaim:
            claimName: mysql-pv-claim
---

# Name service as sql-service
# Map port 3306 of MySQL container to 3306 of the pod

apiVersion: v1
kind: Service
metadata:
  name: sql-service
spec:
  selector:
    app: mysql
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306

```

#### - configmap.yaml
configmap.yaml contains configurations/ConfigMap such as database URL. It passes the database URL to all the replica sets. It avoids the manual labour of configuring hostname in Frontend Applications. ConfigMap should always be executed before they are used in pods.

<br/>

###### configmap.yaml
```yaml
# name config map as 'sql-configmap'
# get mysql server hostname/hosturl from 'sql-service'
# 'sql-service' was created in 'mysql-deployment.yaml'

apiVersion: v1
kind: ConfigMap
metadata:
  name: sql-configmap
data:
  database_url: sql-service
```

#### - flaskapp-deployment.yaml
flaskapp-deployment.yaml has 2 yaml documents:
 - Deployment
 - Service: contains information about networking rules of 'Deployment' or our Flask Api pod deployment

<br/>

###### flaskapp-deployment.yaml
```yaml


# Create our CRUD App deployment with the name 'flaskapi'
# Add name and tag to it
# Set no of replicas/pods to 1
# Set container to pull from anandshivam44/crud-api-python. Use your own image if you have one
# Open port 5000 of pod running crud image
# Add sensitive environment variable from cluster secret manager. MYSQL_DATABASE_USER, MYSQL_DATABASE_PASSWORD, MYSQL_DATABASE_DB. These variables will be picked by our python application and use to connect to the database
# Set MySQL server hostname/host-url from ConfigMap into env variable MYSQL_DATABASE_HOST

apiVersion: apps/v1
kind: Deployment
metadata:
  name: flaskapi
  labels:
    app: flaskapi
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flaskapi
  template:
    metadata:
      labels:
        app: flaskapi
    spec:
      containers:
        - name: crud-api-python
          image: anandshivam44/crud-api-python
          ports:
          - containerPort: 5000
          env:
           - name: MYSQL_DATABASE_USER
             valueFrom:
               secretKeyRef:
                 name: sql-secret
                 key: sql-root-username
           - name: MYSQL_DATABASE_PASSWORD
             valueFrom: 
               secretKeyRef:
                 name: sql-secret
                 key: sql-root-password
           - name: MYSQL_DATABASE_DB
             valueFrom: 
               secretKeyRef:
                 name: sql-secret
                 key: sql-root-database-name
           - name: MYSQL_DATABASE_HOST
             valueFrom: 
               configMapKeyRef:
                 name: sql-configmap
                 key: database_url

---

# Create a service to access our CRUD API
# Name the service 'flaskapi-service'. This name will be later used to access our python application.
# Since this service will be publicly accessible, attach a Load Balancer to it to distribute traffic based on volume.
# map port 5000 of the pod to 5000 of docker image inside
# map port 30,000 to Load Balancer

apiVersion: v1
kind: Service
metadata:
  name: flaskapi-service
spec:
  selector:
    app: flaskapi
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
      nodePort: 30000
```
##### Additional information 
When our CRUD container/pod is run, it will try to connect to the database, If the database is not found in the MySQL server our python app will create a new database using
```sql
CREATE DATABASE flaskapi;
USE flaskapi;
CREATE TABLE users(user_id INT PRIMARY KEY AUTO_INCREMENT, user_name VARCHAR(255), user_email VARCHAR(255), user_password VARCHAR(255));
```

### Step 4: Deploy your application into the k8 cluster  
 - Start minikube
```bash
minikube start
```
 - Optional: to get everything fresh use 
```bash
kubectl delete all --all
```
This will clean up your k8 cluster
A more cleaner way of doing is
```bash
minikube delete
minikube start
```
 - Add all secrets
```bash
kubectl apply -f secret.yaml 

kubectl get secret # to verify if secrets were added
```
 - Deploy your MySQL database
```bash

kubectl apply -f mysql-deployment.yaml

kubectl get pod --watch # watch your pod starting

kubectl describe pod  [replace with pod name] # if pod is taking too long to start to describe pod to see its activity

kubectl logs [replace with pod name] # check logs to see if everything is okay inside pods

kubectl get service # check if your service for MySQL is active

kubectl describe service sql-service # describe service
```
 - Deploy CRUD/python/flask pod
```bash
# apply ConfigMap before flask deployment since flask deployment needs database host URL from ConfigMap 
kubectl apply -f configmap.yaml

# deploy your CRUD API
kubectl apply -f flaskapp-deployment.yml
```
 - Get Service and URL to access your Application
```bash
kubectl get service # get/observe all services

minikube service [service name] # get service url from minikube. Use this URL to access your CRUD Application
```

### Step 5: How to test your deployment
 - Get a Hello World response
```bash
curl http://192.168.49.2:30000
```
 - Add a user to the database 
```bash
curl -H "Content-Type: application/json" -d '{"name": "usernamw1234", "email": "emailid@provider.com", "pwd": "Password@1234"}' http://192.168.49.2:30000/create
```

 - Get all users
```bash
curl http://192.168.49.2:30000/users
```
 - Get user details by index
```bash
curl http://192.168.49.2:30000/user/1
```
 - Delete a user by user_id: 
```bash
curl -H "Content-Type: application/json" -d '{"name": "<user_name>", "email": "<user_email>", "pwd": "<user_password>"}' <service_URL>/delete
```
 - Update a user's information: 
```bash
curl -H "Content-Type: application/json" -d {"name": "<user_name>", "email": "<user_email>", "pwd": "<user_password>", "user_id": <user_id>} <service_URL>/update
```

### Step 6: Cleaning up
Delete everything from the cluster
```bash
kubectl delete all -all
```
or
Delete cluster, delete minikube virtual environment
```bash
minikube delete
```



# phpfpm-nginx-helloworld on minikube
This is a guide to running Nginx and PHP-FPM on Kubernetes. You’ll get an overview of each component in the environment, plus complete source code for running an application using PHP-FPM and Nginx on Kubernetes. This app is containerized and scaleable. It is also set to auto-scale.

###
## create simple hello world php app
create a simple php app and name it hello.php

```
# hello.php
<html>
    <head>
        <title>PHP Hello World!</title>
    </head>
    <body>
        <?php echo '<h1>Hello World</h1>'; ?>
        <?php phpinfo(); ?>
    </body>
</html>

```
###
## create Dockerfile
create a Dockerfile in the same directory to create image of the app

```
FROM php:7.2-fpm
RUN mkdir /app
COPY hello.php /app

```
###
## Build Docker image
Build Docker image by running this command (Don't forget to put the dot):

```sh
docker build -t my-php-app:1.0.0 .
```
###
## create configmap for nginx
Create a yaml file name config.yaml:

```yaml
#config.yaml

kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-config
data:
  nginx.conf: |
    events {
    }
    http {
      server {
        listen 80 default_server;
        listen [::]:80 default_server;
        
        # Set nginx to serve files from the shared volume!
        root /var/www/html;
        server_name _;
        location / {
          try_files $uri $uri/ =404;
        }
        location ~ \.php$ {
          include fastcgi_params;
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          fastcgi_pass 127.0.0.1:9000;
        }
      }
    }
```
create configmap using this command:
```sh
kubectl create -f config.yaml
```

###
## create deployment
create yaml file and name it deployment.yaml:

```yaml
#deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: phpfpm-nginx
  labels:
    app: phpfpm-nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: phpfpm-nginx
  template:
    metadata:
      labels:
        app: phpfpm-nginx
    spec:
      volumes:
        # Create the shared files volume to be used in both pods
        - name: shared-files
          emptyDir: {}
    
        # Add the ConfigMap we declared above as a volume for the pod
        - name: nginx-config-volume
          configMap:
            name: nginx-config
      containers:
        # Our PHP-FPM application
        - image: my-php-app:1.0.0
          name: app
          volumeMounts:
            - name: shared-files
              mountPath: /var/www/html
          lifecycle:
            postStart:
              exec:
                command: ["/bin/sh", "-c", "cp -r /app/. /var/www/html"]
    
      # Our nginx container, which uses the configuration declared above,
      # along with the files shared with the PHP-FPM app.
        - image: nginx:1.7.9
          name: nginx
          volumeMounts:
            - name: shared-files
              mountPath: /var/www/html
            - name: nginx-config-volume
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
```
create deployment using this command:
```sh
kubectl create -f deployment.yaml
```
###
## expose containers via minikube node-port
Write below command:
```sh
kubectl expose deploy phpfpm-nginx --type=NodePort --port=80
```
###
## open in browser
Write below command:
```sh
minikube service phpfpm-nginx
```
If it says "403 forbidden" add /hello.php after the address like this:
your-IP:your-port/hello.php

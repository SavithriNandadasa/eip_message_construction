# Message Construction Patterns

Message construction patterns describes the creation of message content that travel across the messaging system.Java Message 
Service (JMS) is used to send messages between two or more clients. JMS supports two models: point-to-point model and 
publish/subscribe model. 

A JMS synchronous invocation takes place when a JMS producer receives a response to a JMS request produced by it when invoked.
This is a simple example of how to use messaging, implemented in JMS. It shows how to implement Request-Reply, where a requestor application sends a request, a replier application receives the request and returns a reply, and the requestor receives the reply. 

> This guide walks you through the process of using Ballerina to message construction with JMS queues using a message broker.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build
To understand how you can use JMS queues for messaging, let's consider a real-world use case of a phone store service using which a user can order phones for home delivery. This scenarion contains two services.
- phone_store_service : A Message Endpoint that sends a request message and waits to receive a reply message as a response.
- phone_order_delivery_service : A Message Endpoint that waits to receive the request message; when it does, it responds by sending the reply message.

Once an order is placed, the phone_store_service will add it to a JMS queue named "OrderQueue" if the order is valid. Hence, this phonestore service acts as the message requestor. And phone_order_delivery_service, which acts as the message replier   and gets the order details whenever the queue becomes populated and forward them to delivery queue using phone_order_delivery_service.

As this usecase based on message construction patterns , the scenario use Request-Reply with a pair of Point-to-Point Channels. The request is a Command Message whereas the reply is a Document Message that contains the function's return value or exception.


The below diagram illustrates this use case.

## image

In this example `Apache ActiveMQ` has been used as the JMS broker. Ballerina JMS Connector is used to connect Ballerina 
and JMS Message Broker. With this JMS Connector, Ballerina can act as both JMS Message Consumer and JMS Message  
Producer.

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A JMS Broker (Example: [Apache ActiveMQ](http://activemq.apache.org/getting-started.html))
  * After installing the JMS broker, copy its .jar files into the `<BALLERINA_HOME>/bre/lib` folder
    * For ActiveMQ 5.15.4: Copy `activemq-client-5.15.4.jar`, `geronimo-j2ee-management_1.1_spec-1.0.1.jar` and `hawtbuf-1.11.jar`
- A Text Editor or an IDE 

### Optional Requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the source from the Git repo and directly move to the "Testing" section by skipping the "Implementation" section.    

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.
```
message_construction_patterns
 └── guide
      ├── phone_store_service
      │    ├── phone_store_service.bal
      │    └── tests
      │         └── phone_store_service.bal
      └── phone_order_delivery_service
           ├──order_delivery_service.bal
           └── tests
                └── phone_order_delivery_service_test.bal

```

- Create the above directories in your local machine and also create empty `.bal` files

- Then open the terminal and navigate to `message_construction_patterns/guide` and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```
### Developing the service

Let's get started with the implementation of the phone_store_service, which acts as the message Replier. 
Refer to the code attached below. Inline comments added for better understanding.

##### phone_store_service.bal

``````
code
``````
Now let's consider the implementation of order_delivery_service.bal which acts as the message Requestor.

#### order_delivery_service.bal

``````
code
``````

## Testing 

### Invoking the service

- First, start the `Apache ActiveMQ` server by entering the following command in a terminal from `<ActiveMQ_BIN_DIRECTORY>`.

```bash
   $ ./activemq start
```

- Navigate to `message_construction_patterns/guide` and run the following commands in separate terminals to start both `phone_store_service` and `order_delivery_service`.
```bash
   $ ballerina run phone_store_service.bal
```

```bash
   $ ballerina run order_delivery_system
```
   
- Invoke the `phone_store_service` by sending a GET request to check the available books.

```bash
   curl -v -X GET localhost:9090/phonestore/getPhoneList
```

  The phone_store_service sends a response similar to the following.
```
   < HTTP/1.1 200 OK
   ["Apple:190000","Samsung:150000","Nokia:80000","HTC:40000","Huawei:100000"]
```
   
- Place an order using the following command.

```bash
   curl -v -X POST -d \
   '{"Name":"John", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94718930874", "PhoneName":"Apple:190000"}' \
   "http://localhost:9090/phonestore/placeOrder" -H "Content-Type:application/json"
   
```

  The bookstoreService sends a response similar to the following.
```
   < HTTP/1.1 200 OK
   {"Message":"Your order is successfully placed. Ordered book will be delivered soon"} 
```

  Sample Log Messages:
```bash

  INFO  [phone_store_service] - order will be added to the order  Queue; CustomerName: 'Bob', OrderedPhone: 'Apple:190000'; 
  INFO  [phone_store_service] - New order successfilly received from the Order Queue 
  INFO  [phone_store_service] - Order Details: {"customerName":"John","address":"20, Palm Grove, Colombo, Sri Lanka","contactNumber":"+94718930874","orderedPhoneName":"Apple:190000"} 
  
  Order Details have sent to phone_order_delivery_service.


  Order Details have received from phone_store_service
  
  INFO  [phone_order_delivery_service] - order Delivery details  added to the delivery  Queue; CustomerName: 'Bob', OrderedPhone: 'Apple:190000'; 
  INFO  [phone_order_delivery_service] - New order successfilly received from the Delivery Queue 
  INFO  [phone_order_delivery_service] - Order Details: {"customerName":"Bob","address":"20, Palm Grove, Colombo, Sri Lanka","contactNumber":"+94777123456","orderedPhoneName":"Apple:190000"} 
  
 Delivery Details sent to the customer successfully
 
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named `tests`.  When writing the test functions the below convention should be followed.
- Test functions should be annotated with `@test:Config`. See the below example.

```ballerina
   @test:Config
   function testResourcePlaceOrder() {
```
  
This guide contains unit test cases for each resource available in the 'bookstore_service' implemented above. 

To run the unit tests, navigate to `message_construction_patterns/guide` and run the following command. 
```bash
   $ ballerina test
```

When running these unit tests, make sure that the JMS Broker is up and running.

## Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below. 

### Deploying locally

As the first step, you can build Ballerina executable archives (.balx) of the services that we developed above. Navigate to `message_construction_patterns/guide` and run the following command.

```bash
   $ ballerina build
```

- Once the .balx files are created inside the target folder, you can run them using the following command. 
```bash
   $ ballerina run target/<Exec_Archive_File_Name>
```

- The successful execution of a service will show us something similar to the following output.
```
   ballerina: initiating service(s) in 'phone_store.balx' 
   ballerina: started HTTP/WS endpoint 0.0.0.0:9090
   
   ballerina: initiating service(s) in 'phone_order_delivery_service.balx' 
   ballerina: started HTTP/WS endpoint 0.0.0.0:9091
```
### Deploying on Docker

You can run the service that we developed above as a Docker container.
As Ballerina platform includes [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support for running ballerina programs on containers,
you just need to add the corresponding Docker annotations to your service code.
Since this guide requires `ActiveMQ` as a prerequisite, you need a couple of more steps to configure it in a Docker container.   

First let's see how to configure `ActiveMQ` in a Docker container.

- Initially, you need to pull the `ActiveMQ` Docker image using the following command.
```bash
   $ docker pull webcenter/activemq
```

- Then launch the pulled image using the following command. This will start the `ActiveMQ` server in Docker with default configurations.
```bash
   $ docker run -d --name='activemq' -it --rm -P webcenter/activemq:latest
```

- Check whether the `ActiveMQ` container is up and running using the following command.
```bash
   $ docker ps
```

Now let's see how we can deploy the `phone_store_service` and `phone_order_delivery_service` on Docker. We need to import `ballerinax/docker` and use the annotation `@docker:Config` as shown below to enable Docker image generation at build time. 

##### phone_store_service.bal
```ballerina
import ballerinax/docker;
// Other imports

// Type definition for a phone order

json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

// 'jms:Connection' definition

// 'jms:Session' definition

// 'jms:QueueSender' endpoint definition

@docker:Config {
    registry:"ballerina.guides.io",
    name:"bookstore_service",
    tag:"v1.0"
}


@docker:Expose{}
endpoint http:Listener listener {
    port:9090
};


@http:ServiceConfig {basePath:"/phonestore"}
service<http:Service> phone_store_service bind listener {
``` 
Similar to the `phone_store_service.bal`, We define the `@docker:Config` and `@docker:Expose {}` in  `phone_order_delivery_service` for Docker deployment.

- `@docker:Config` annotation is used to provide the basic Docker image configurations for the sample.`@docker:Expose {}` is used to expose the port. 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. This will also create the corresponding Docker image using the Docker annotations that you have configured above. Navigate to `message_construction_patterns/guide` and run the following command.  
  
```
   $ballerina build 
  
   ./target/phone_store.balx
        @docker                  - complete 3/3 

        Run following command to start docker container:
        docker run -d -p 9090:9090 ballerina.guides.io/phone_store_service:v1.0

    ./target/phone_order_delivery_service.balx
        @docker                  - complete 3/3 

        Run following command to start docker container:
        docker run -d -p 9091:9091 ballerina.guides.io/phone_order_delivery_service:v1.0

```

- Once you successfully build the Docker image, you can run it with the `` docker run`` command that is shown in the previous step.  

```bash
  docker run -d -p 9090:9090 ballerina.guides.io/phone_store_service:v1.0
  docker run -d -p 9091:9091 ballerina.guides.io/phone_order_delivery_service:v1.0  
```

   Here we run the Docker image with flag`` -p <host_port>:<container_port>`` so that we use the host port 9090 and the container port 9090. Therefore you can access the service through the host port. 

- Verify docker container is running with the use of `` $ docker ps``. The status of the Docker container should be shown as 'Up'. 

- You can access the service using the same curl commands that we've used above.
```bash
    curl -v -X POST -d \
   '{"Name":"John", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94718930874", "PhoneName":"Apple:190000"}' \
   "http://localhost:9090/phonestore/placeOrder" -H "Content-Type:application/json"
```
### Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support to run a Ballerina program on Kubernetes, with the use of Kubernetes annotations that you can include as part of your 
service code. Also, it will take care of the creation of the Docker images. So you don't need to explicitly create Docker images prior to deploying it on Kubernetes. Refer [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 

- Since this guide requires `ActiveMQ` as a prerequisite, you need an additional step to create a pod for `ActiveMQ` and use it with our sample.  

- Navigate to `message_construction_patterns/resources` directory and run the below command to create the ActiveMQ pod by creating a deployment and service for ActiveMQ. You can find the deployment descriptor and service descriptor in the `./resources/kubernetes` folder.

```bash
   $ kubectl create -f ./kubernetes/
```

- Now let's see how we can deploy the `phone_store_service` on Kubernetes. We need to import `` ballerinax/kubernetes; `` and use `` @kubernetes `` annotations as shown below to enable kubernetes deployment.

#####  phone_store_service.bal

```ballerina
import ballerinax/kubernetes;
// Other imports

// Type definition for a phone order

json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

// 'jms:Connection' definition

// 'jms:Session' definition

// 'jms:QueueSender' endpoint definition

@kubernetes:Ingress {
hostname:"ballerina.guides.io",
name:"ballerina-guides-phone_store_service",
path:"/"
}

@kubernetes:Service {
serviceType:"NodePort",
name:"ballerina-guides-phone_store_service"
}

@kubernetes:Deployment {
image:"ballerina.guides.io/phone_store_service:v1.0",
name:"ballerina-guides-phone_store_service"
}

endpoint http:Listener listener {
port:9090
};

@http:ServiceConfig {basePath:"/phonestore"}
service<http:Service> phone_store_service bind listener {
``` 

- Here we have used ``  @kubernetes:Deployment `` to specify the Docker image name which will be created as part of building this service. 
- We have also specified `` @kubernetes:Service `` so that it will create a Kubernetes service, which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes:Ingress ``, which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. This will also create the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
   $ ballerina build 
   
   @kubernetes:Service                      - complete 1/1
   @kubernetes:Ingress                      - complete 1/1
   @kubernetes:Docker                       - complete 3/3 
   @kubernetes:Deployment                   - complete 1/1
  
   Run following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/phone_store_service/kubernetes
   
   @kubernetes:Service                      - complete 1/1
   @kubernetes:Ingress                      - complete 1/1
   @kubernetes:Docker                       - complete 3/3 
   @kubernetes:Deployment                   - complete 1/1
  
   Run following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/phone_order_delivery_service/kubernetes
  
   
```

- You can verify that the Docker image that we specified in `` @kubernetes:Deployment `` is created, by using `` docker images ``. 
- Also the Kubernetes artifacts related our service, will be generated under `` ./target/phone_store_service/kubernetes`` and ``/target/phone_order_delivery_service/kubernetes``. 
- Now you can create the Kubernetes deployment using:

```bash
   $ kubectl apply -f ./target/phone_store_service/kubernetes
   
   deployment.extensions "ballerina-guides-phone_store_service" created
   ingress.extensions "ballerina-guides-phone_store_service" created
   service "ballerina-guides-phone_store_service" created
   
   kubectl apply -f ./target/phone_order_delivery_service/kubernetes
   
   deployment.extensions "ballerina-guides-phone_order_delivery_service" created
   ingress.extensions "ballerina-guides-phone_order_delivery_service" created
   service "ballerina-guides-phone_order_delivery_service" created
```

- You can verify Kubernetes deployment, service and ingress are running properly, by using following Kubernetes commands. 

```bash
   $ kubectl get service
   $ kubectl get deploy
   $ kubectl get pods
   $ kubectl get ingress
```

- If everything is successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
```bash
    curl -v -X POST -d \
   '{"Name":"John", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94718930874", "PhoneName":"Apple:190000"}' \
   "http://localhost:9090/phonestore/placeOrder" -H "Content-Type:application/json"  
```

Ingress:

Add `/etc/hosts` entry to match hostname. 
``` 
   127.0.0.1 ballerina.guides.io
```

Access the service 
```bash
    curl -v -X POST -d \
   '{"Name":"John", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94718930874", "PhoneName":"Apple:190000"}' \
   "http://localhost:9090/phonestore/placeOrder" -H "Content-Type:application/json" 
```



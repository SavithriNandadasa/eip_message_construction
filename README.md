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


  Order Details have received to phone_order_delivery_service
  
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


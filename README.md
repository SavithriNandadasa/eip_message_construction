# Message Construction

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


Once an order is placed, the phone_store_service will add it to a JMS queue named "OrderQueue" if the order is valid. Hence, this phonestore service acts as the message requestor. And phone_order_delivery_service, which acts as the message replier  "OrderQueue" and gets the order details whenever the queue becomes populated and forward them to delivery queue using phone_order_delivery_service.The below diagram illustrates this use case.

##image

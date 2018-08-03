import ballerina/log;
import ballerina/http;
import ballerina/jms;
import ballerina/io;



public http:Request backendreq;

// Type definition for a phone order
type phoneOrder record {
    string customerName;
    string address;
    string contactNumber;
    string orderedPhoneName;
};

// Global variable containing all the available phones
json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

// Initialize a JMS connection with the provider
// 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use
// 'Apache ActiveMQ' has been used as the message broker in this example
jms:Connection jmsConnection = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });


// Initialize a queue sender using the created session
endpoint jms:QueueSender jmsProducer {
    session:jmsSession,
    queueName:"OrderQueue"
};

// Service endpoint
endpoint http:Listener listener {
    port:9090
};


// phone store service, which allows users to order phones online for delivery
@http:ServiceConfig {basePath:"/phonestore"}
service<http:Service> phonestoreService bind listener {
    // Resource that allows users to place an order for a phone
    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"],
        produces: ["application/json"] }

    placeOrder(endpoint caller, http:Request request) {
        backendreq= untaint request;
        http:Response response;
        phoneOrder newOrder;
        json reqPayload;

        // Try parsing the JSON payload from the request
        match request.getJsonPayload() {
            // Valid JSON payload
            json payload => reqPayload = payload;
            // NOT a valid JSON payload
            any => {
                response.statusCode = 400;
                response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = caller -> respond(response);
                done;
            }
        }

        json name = reqPayload.Name;
        json address = reqPayload.Address;
        json contact = reqPayload.ContactNumber;
        json phoneName = reqPayload.PhoneName;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == null || address == null || contact == null || phoneName == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid payload"});
            _ = caller -> respond(response);
            done;
        }

        // Order details
        newOrder.customerName = name.toString();
        newOrder.address = address.toString();
        newOrder.contactNumber = contact.toString();
        newOrder.orderedPhoneName = phoneName.toString();

        // boolean variable to track the availability of a requested phone
        boolean isPhoneAvailable;
        // Check whether the requested phone available
        foreach phone in phoneInventory {
            if (newOrder.orderedPhoneName.equalsIgnoreCase(phone.toString())) {
                isPhoneAvailable = true;
                break;
            }
        }

        json responseMessage;
        // If the requested phone is available, then add the order to the 'OrderQueue'
        if (isPhoneAvailable) {
            var phoneOrderDetails = check <json>newOrder;
            // Create a JMS message
            jms:Message queueMessage = check jmsSession.createTextMessage(phoneOrderDetails.toString());


            log:printInfo("order will be added to the order  Queue; CustomerName: '" + newOrder.customerName +
                    "', OrderedPhone: '" + newOrder.orderedPhoneName + "';");


            // Send the message to the JMS queue
            _ = jmsProducer -> send(queueMessage);


            // Construct a success message for the response
            responseMessage = {"Message":"Your order is successfully placed. Ordered phone will be delivered soon"};

        }
        else {
            // If phone is not available, construct a proper response message to notify user
            responseMessage = {"Message":"Requested phone not available"};
        }

        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = caller -> respond(response);
    }

    // Resource that allows users to get a list of all the available phones
    @http:ResourceConfig {methods:["GET"], produces:["application/json"]}
    getPhoneList(endpoint client, http:Request request) {
        http:Response response;
        // Send json array 'phoneInventory' as the response, which contains all the available phones
        response.setJsonPayload(phoneInventory);
        _ = client -> respond(response);
    }
}


jms:Connection conn = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession3 = new(conn, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session


endpoint jms:QueueReceiver jmsConsumer {
    session:jmsSession3,
    queueName:"OrderQueue"
};


// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service<jms:Consumer> orderDeliverySystem bind jmsConsumer {
    // Triggered whenever an order is added to the 'OrderQueue'
    onMessage(endpoint consumer, jms:Message message) {
        log:printInfo("New order successfilly received from the Order Queue");
        // Retrieve the string payload using native function
        string stringPayload = check message.getTextMessageContent();
        log:printInfo("Order Details: " + stringPayload);

        http:Request enrichedreq = backendreq;
        var clientResponse = phonedetailsproviderServiceEP->forward("/", enrichedreq);
        match clientResponse {
            http:Response res => {
                io:println("Delivery Details sent to the customer successfully.");
            }
            error err => {
                io:println("forward error..................");
            }
        }


    }
}

endpoint http:Client phonedetailsproviderServiceEP {
    url: "http://localhost:9091/phonestore1/placeOrder1"

};

//Creating the Delivery Queue

jms:Connection jmsConnection2 = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a queue sender using the created session
endpoint jms:QueueSender jmsProducer2 {
    session:jmsSession2,
    queueName:"DeliveryQueue"
};

// Initialize a JMS session on top of the created connection
jms:Session jmsSession2 = new(jmsConnection2, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });



// Service endpoint
endpoint http:Listener listener1 {
    port:9091
};

@http:ServiceConfig {basePath:"/phonestore1"}
// phone store service, which allows users to order phones online for delivery
service<http:Service> phonedetailsproviderService bind listener1 {
    // Resource that allows users to place an order for a phone
    @http:ResourceConfig { consumes: ["application/json"],
        produces: ["application/json"] }

    placeOrder1(endpoint caller, http:Request enrichedreq) {
        http:Response response;
        phoneOrder newOrder;
        json reqPayload;


        io:println("Order Details have received to Phone Store");


        // Try parsing the JSON payload from the request
        match  enrichedreq.getJsonPayload() {
            // Valid JSON payload
            json payload => reqPayload = payload;
            // NOT a valid JSON payload
            any => {
                response.statusCode = 400;
                response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = caller -> respond(response);
                done;
            }
        }

        json name = reqPayload.Name;
        json address = reqPayload.Address;
        json contact = reqPayload.ContactNumber;
        json phoneName = reqPayload.PhoneName;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == null || address == null || contact == null || phoneName == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid payload"});
            _ = caller -> respond(response);
            done;
        }

        // Order details
        newOrder.customerName = name.toString();
        newOrder.address = address.toString();
        newOrder.contactNumber = contact.toString();
        newOrder.orderedPhoneName = phoneName.toString();

        // boolean variable to track the availability of a requested phone
        boolean isPhoneAvailable;
        // Check whether the requested phone available
        foreach phone in phoneInventory {
            if (newOrder.orderedPhoneName.equalsIgnoreCase(phone.toString())) {
                isPhoneAvailable = true;
                break;
            }
        }

        json responseMessage;
        // If the requested phone is available, then add the order to the 'OrderQueue'
        if (isPhoneAvailable) {
            var phoneOrderDetails = check <json>newOrder;
            // Create a JMS message

            jms:Message queueMessage2 = check jmsSession2.createTextMessage(phoneOrderDetails.toString());

            log:printInfo("order Delivery details  added to the delivery  Queue; CustomerName: '" + newOrder.customerName +
                    "', OrderedPhone: '" + newOrder.orderedPhoneName + "';");

            // Send the message to the JMS queue
            _ = jmsProducer2 -> send(queueMessage2);

            // Construct a success message for the response
            responseMessage = {"Message":"Your order is successfully placed. Ordered phone will be delivered soon"};

        }
        else {
            // If phone is not available, construct a proper response message to notify user
            responseMessage = {"Message":"Requested phone not available"};
        }

        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = caller -> respond(response);
    }

}


jms:Connection conn2 = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession4 = new(conn2, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session


endpoint jms:QueueReceiver jmsConsumer2 {
    session:jmsSession4,
    queueName:"DeliveryQueue"
};


service<jms:Consumer> deliverySystem bind jmsConsumer2 {
    // Triggered whenever an order is added to the 'OrderQueue'
    onMessage(endpoint consumer, jms:Message message2) {
        log:printInfo("New order successfilly received from the Delivery Queue");
        // Retrieve the string payload using native function
        string stringPayload2 = check message2.getTextMessageContent();
        log:printInfo("Order Details: " + stringPayload2);



    }
}


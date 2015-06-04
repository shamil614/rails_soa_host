# Ruby on Rails Based Host App that Consumes other Services
This rails application is designed as a test bed for consuming Services (microservices)
At this time the only service linked to the application is the [calculator_service] (https://github.com/shamil614/calculator_service).

## Installation
Use bundler to install the gems. ```bundle install```


## Usage
Use the console to interface with Consumer class. ```rails console```
A rake task is setup to run a basic test on the service both via AMQP and HTTP
To run the rake task make sure the calculator_service is running (see link above). Next run ```rake benchmark:calculator```.

## TODOs
1. Add tests.
2. HTTP benchmarks are very slow. Prbably because it's blocking on each request.  Try threads.

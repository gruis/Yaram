# Yet Another Ruby Actor Model
Yaram provides an Actor Model for Ruby. It is loosely based on the Erlang and Scala actor models.

## Fundamental concepts
In the actor model, each object is an actor. This is an entity that has a mailbox and a behaviour. Messages can be exchanged between actors, which will be buffered in the mailbox. Upon receiving a message, the behaviour of the actor is executed, upon which the actor can: send a number of messages to other actors, create a number of actors and assume new behaviour for the next message to be received.

Of importance in this model is that all communications are performed asynchronously. This implies that the sender does not wait for a message to be received upon sending it, it immediately continues its execution. There are no guarantees in which order messages will be received by the recipient, but they will eventually be delivered.

A second important property is that all communications happen by means of messages: there is no shared state between actors. If an actor wishes to obtain information about the internal state of another actor, it will have to use messages to request this information. This allows actors to control access to their state, avoiding problems like the lost-update problem. Manipulation of the internal state also happens through messages.

Each actor runs concurrently with other actors: it can be seen as a small independently running process.

["Concurrency in Erlang & Scala: The Actor Model - Ruben Vermeersch"][1]

An actor is a computational entity that, in response to a message it receives, can concurrently:

- send a finite number of messages to other actors;
- create a finite number of new actors;
- designate the behavior to be used for the next message it receives.

There is no assumed sequence to the above actions and they could be carried out in parallel.

["Actor model - CBM & Tbhotch, et al."][2]




[1]: http://ruben.savanne.be/articles/concurrency-in-erlang-scala 	"Concurrency in Erlang & Scala: The Actor Model - Ruben Vermeersch"
[2]:  http://en.wikipedia.org/wiki/Actor_model  "Actor model - CBM & Tbhotch, et al."
# memcached-server

## Dependencies
First, make sure you have Ruby installed.

**On a Mac**, open `/Applications/Utilities/Terminal.app` and type:

    ruby -v

If the output looks something like this, you're in good shape:

    ruby 3.0.0p0 (2020-12-25 revision 95aff21468) [x86_64-darwin18]

If the output looks more like this, you need to [install Ruby][ruby]:

[ruby]: https://www.ruby-lang.org/en/downloads/

    ruby: command not found

**On Linux**, for Debian-based systems, open a terminal and type:

    sudo apt-get install ruby-dev

or for Red Hat-based distros like Fedora and CentOS, type:

    sudo yum install ruby-devel

(if necessary, adapt for your package manager)

**On Windows**, you can install Ruby with [RubyInstaller][rubyinstaller].

[rubyinstaller]: http://rubyinstaller.org/downloads/


## Usage

### Running the memcached server
In the directory you cloned this repository, you'll have to type into the terminal:
  
    ruby server.rb

This will host the server in the 3000 port by default.
 **To change the port** look for the following and type in the value:
  
    @server = TCPServer.open(3000)

### Connecting with the memcached
You'll need to use a client to connect to the server, the connection is via **TCP Socket**, as TCP/IP is the standard network protocol for this.
Luckily, Ruby provides **socket** as a native library.

    require 'socket'
    hostname = 'localhost'
    port = 3000
    s = TCPSocket.open(hostname, port)
    
In this particular example, I'm using *localhost* as *hostname* because the memcached is not running on any external server.

We have 2 basic interactions with the socket (s).
One of them is the **gets**, it's used to retrieve the data that the other end of the socket stored in it:

    s.gets data
    
The other is the **puts**, it's used to post data to the socket, so the other end can retrieve it:

    s.puts data

*data is the variable you're passing onto the method*

### Clients
I like to separate clients in two types, the **read** and **write**. This criteria is driven by the types of operation each client performs, and the main technical difference between them is the ammount of **puts** they perform per query.
**Read Client** performs only one puts to the server whereas the **Write Client** performs two of them.

***Example clients are provided in the code and they are pretty self-explainatory.***

**Retrieving the server's response**.
From the client, you can retrieve the server's response by performing a **gets**, as showed above.
This response varies depending on what kind of query did you make.

For example, a read command can throw either an error or a valid response with the information asked.
A write command will always recieve a status of the operation: "STORED", "NOT_STORED", etc.


### Commands
Now that we have a good general understanding of the communication structure, let's move onto the commands.
Same as clients we have two kinds of commands:

**Read**

    get
    gets
    
**Write**

    set
    add
    replace
    append
    prepend
    cas
    
We'll begin by stating the structure for the commands to see how they should be written.
The *write* command structure is the following:

    prefix key flags expt bytes [cas_given]
    data_block
    
One example could be: 

    add nacho 0 1200 5
    autos
    
But what are all these parameters? we'll break them down one by one:

#### **key**
The key will be the data identifier

#### **flags**
Used to classify data according to client preferences

#### **expt**
expt stands for expiration time, and it's the ammount of seconds the data will remain stored before it's deletion
This parameter should always be a number, and 0 means the data will remain forever stored.

#### **bytes**
The ammount of information that will be stored in the block, should as well always be a number.
If the bytes param is greater or equal than the size of the data_block, it'll be stored right away, otherwise, the data_block will be trimmed so it fits the stated size of it.

examples on this:

    add nacho 0 200 5
    autos
the data_block stored will be **autos**

    add nacho 0 200 4
    autos
the data_block stored will be **auto**


#### **cas given**
This is an optional parameter, only used in the **cas** command, and it's a number as well.
It's a unique key up to six figures generated randomly depending in the data creation timestamp and the content of the data_block, used to check if a certain data remained unchanged since the last time a the client fetched it.


The *read* command structure is the following:

    prefix key [key] [key] ...
    
One example could be: 

    get nacho nacho
This get command will give us the following:

    VALUE 0 5
    autos
    VALUE 0 5
    autos
    END
    

## Data structure
The data is structured in a hash

    @cached_data = {
        "nacho" => [{
            key: 'nacho', 
            flags: '0',
            expiration_time: 1200,
            bytes: 40,
            created_at: 16231328,
            cas_key: 465378,
            cas_given: nil,
            data_block: 'autos'
        }, 
        {
            key: 'nacho', 
            flags: '0',
            expiration_time: 1000,
            bytes: 30,
            created_at: 16231334,
            cas_key: 712385,
            cas_given: nil,
            data_block: 'motos'
        }]
    }
    
So it's basically

    cached_data = {
        key -> array of objects,
        key -> array of objects,
        ... and so on
    }
    

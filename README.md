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



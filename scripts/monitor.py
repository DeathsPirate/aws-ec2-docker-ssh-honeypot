import sys
import docker
import logging
import threading
import os
import subprocess      
import boto3

logging.basicConfig(filename='/var/log/docker_start.log', level=logging.INFO)

threads = []
sc = []

def cleanup(container):
    container.stop()
    _ = subprocess.call(["/usr/local/bin/honey-clean.sh", container.name])

    exists = container.id in sc    

    if exists:
        s3 = boto3.resource('s3')
        BUCKET= "honeypot-docker-images"
        shell_command = "docker export -o /tmp/" + container.id + ".tar " + container.name           
        _ = subprocess.call(shell_command.split())
        s3.Bucket(BUCKET).upload_file("/tmp/" + container.id + ".tar", container.name + "/" + container.id + ".tar")
        os.remove("/tmp/" + container.id + ".tar")
        sc.remove(container.id)
    
    container.remove()

def containerTimeout(id, container):
    cleanup(container)


def container(cli,id):
    failed = 0
    container = cli.containers.get(id)
    
    # timer to kill the container after 5 minutes
    tr = threading.Timer(5 * 60, containerTimeout, [id, container])
    tr.start()
    
    logline = []
    for line in container.logs(stream=True):
        if '\n' in line.decode('utf-8'):
            logline = ''.join(logline)
            
            if 'Accepted password for' in line.decode('utf-8'):
                sc.append(container.id)

            if 'closed' in line.decode('utf-8'):
                container.stop()
                container.remove()
                break
            
            if 'disconnected' in line.decode('utf-8'):
                cleanup(container)
                break
        
            #logging.info(str(logline + line.decode('utf-8').strip()))
            logline = []
        else:
            logline.append( line )
    return

def start(cli, event):
    """ handle 'start' events"""
    logging.info(event)
    t = threading.Thread(target=container, args=(cli,event.get('id'),))
    threads.append(t)
    t.start()


thismodule = sys.modules[__name__]
# create a docker client object that talks to the local docker daemon 
cli = docker.from_env()
# start listening for new events
#containers = cli.containers.list()

# start listening for new events
events = cli.events(decode=True)
# possible events are: 
#  attach, commit, copy, create, destroy, die, exec_create, exec_start, export, 
#  kill, oom, pause, rename, resize, restart, start, stop, top, unpause, update
for event in events:
    # if a handler for this event is defined, call it
    if (hasattr( thismodule , event['Action'])):
        getattr( thismodule , event['Action'])( cli, event )

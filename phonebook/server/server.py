import grpc
from concurrent import futures
import threading
import json
import os
from dotenv import load_dotenv
import gRPC_pb2 as pb2
import gRPC_pb2_grpc as pb2_grpc

load_dotenv()

HOST = os.getenv("HOST", "0.0.0.0")
PORT = os.getenv("PORT", "50051")
DB_FILE = os.getenv("DB_FILE", "contacts.json")


# Main gRPC service class
class PhonebookService(pb2_grpc.PhonebookServicer):
    def __init__(self, db_file=DB_FILE):
        self.db_file = db_file
        self.lock = threading.RLock()
        self.contacts = self._load_contacts()

    # Load contacts from json with thread lock
    def _load_contacts(self):
        if os.path.exists(self.db_file):
            with open(self.db_file, "r") as file:
                return json.load(file)
        return {}

    # Save contacts to json with thread lock
    def _save_contacts(self):
        with self.lock:
            with open(self.db_file, "w") as file:
                json.dump(self.contacts, file, indent=4)


    def AddContact(self, request, context):
        '''
        gRPC function
        Adds contact to user with id == peer id 
        '''

        client_id = context.peer()
        with self.lock:
            if client_id not in self.contacts:
                self.contacts[client_id] = {}
            self.contacts[client_id][request.name] = request.number
            self._save_contacts()
        return pb2.Response(status="SUCCESS", message=f"Contact {request.name} added.")

    def GetContact(self, request, context):
        '''
        gRPC function
        Gets contact with user id == peer id 
        '''

        client_id = context.peer()  
        with self.lock:
            if client_id in self.contacts and request.name in self.contacts[client_id]:
                return pb2.Contact(name=request.name, number=self.contacts[client_id][request.name])
        context.set_code(grpc.StatusCode.NOT_FOUND)
        context.set_details(f"Contact {request.name} not found")
        return pb2.Contact()

    def DeleteContact(self, request, context):
        '''
        gRPC function
        Deletes contact contact with user id == peer id, and name == request.name
        '''

        client_id = context.peer()
        with self.lock:
            if client_id in self.contacts and request.name in self.contacts[client_id]:
                del self.contacts[client_id][request.name]
                self._save_contacts()
                return pb2.Response(status="SUCCESS", message=f"Contact {request.name} deleted")
        context.set_code(grpc.StatusCode.NOT_FOUND)
        context.set_details(f"Contact {request.name} not found.")
        return pb2.Response()

    def ListContacts(self, request, context):
        '''
        gRPC function
        Lists all contacts with user id == peer id
        '''

        client_id = context.peer()
        with self.lock:
            if client_id in self.contacts:
                contact_list = [pb2.Contact(name=name, number=number) for name, number in self.contacts[client_id].items()]
                return pb2.ContactList(contacts=contact_list)
        return pb2.ContactList()

def serve():
    '''
    gRPC sereve fuction
    Shutdowns on CTRL+C
    '''

    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    pb2_grpc.add_PhonebookServicer_to_server(PhonebookService(), server)
    server.add_insecure_port(f"{HOST}:{PORT}")
    print(f"Server started on {HOST}:{PORT}")
    server.start()
    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        server.stop(0)
        print("Shutting down...")

if __name__ == "__main__":
    serve()